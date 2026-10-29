package linecount

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"strings"
)

type Result struct {
	Lines int `json:"lines"`
}

// NewHandler is a driving adapter: it translates HTTP into a concrete operation.
func NewHandler(cfg Config) (http.Handler, error) {
	if err := cfg.Validate(); err != nil {
		return nil, err
	}
	mux := http.NewServeMux()
	mux.HandleFunc("POST /count", func(w http.ResponseWriter, r *http.Request) {
		lines, err := Count(r.Context(), r.Body, cfg.MaxBytes)
		if err != nil {
			switch {
			case errors.Is(err, ErrTooLarge):
				http.Error(w, "input too large", http.StatusRequestEntityTooLarge)
			case errors.Is(err, context.Canceled), errors.Is(err, context.DeadlineExceeded):
				http.Error(w, "request canceled or timed out", http.StatusRequestTimeout)
			default:
				http.Error(w, "cannot read input", http.StatusBadRequest)
			}
			return
		}
		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(Result{Lines: lines}); err != nil {
			// A response already started cannot be replaced with another status.
			slog.Error("write count response", "error", err)
		}
	})
	return mux, nil
}

// Demo makes one real loopback HTTP request and always shuts down its server.
// It uses an ephemeral port, no proxy, and no signal or manual shutdown step.
func Demo(ctx context.Context, cfg Config, out io.Writer) (err error) {
	handler, err := NewHandler(cfg)
	if err != nil {
		return err
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return fmt.Errorf("listen: %w", err)
	}
	server := &http.Server{
		Handler:           handler,
		ReadHeaderTimeout: cfg.Timeout,
		ReadTimeout:       cfg.Timeout,
		WriteTimeout:      cfg.Timeout,
	}
	served := make(chan error, 1)
	go func() {
		served <- server.Serve(listener)
	}()
	defer func() {
		// The request may be canceled. Shutdown needs a fresh, bounded context.
		shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.Timeout)
		defer cancel()
		shutdownErr := server.Shutdown(shutdownCtx)
		if shutdownErr != nil {
			shutdownErr = errors.Join(shutdownErr, server.Close())
		}
		serveErr := <-served
		if errors.Is(serveErr, http.ErrServerClosed) {
			serveErr = nil
		}
		err = errors.Join(err, shutdownErr, serveErr)
	}()

	transport := &http.Transport{}
	defer transport.CloseIdleConnections()
	client := &http.Client{Transport: transport, Timeout: cfg.Timeout}
	request, err := http.NewRequestWithContext(ctx, http.MethodPost,
		"http://"+listener.Addr().String()+"/count", strings.NewReader("red\nblue\n"))
	if err != nil {
		return err
	}
	response, err := client.Do(request)
	if err != nil {
		return fmt.Errorf("request: %w", err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return fmt.Errorf("unexpected HTTP status: %s", response.Status)
	}
	var result Result
	if err := json.NewDecoder(response.Body).Decode(&result); err != nil {
		return fmt.Errorf("decode response: %w", err)
	}
	if result.Lines != 2 {
		return fmt.Errorf("expected 2 lines, got %d", result.Lines)
	}
	_, err = fmt.Fprintf(out, "HTTP %d lines=%d\n", response.StatusCode, result.Lines)
	return err
}

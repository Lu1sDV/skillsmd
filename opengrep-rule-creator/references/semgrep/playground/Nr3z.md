# Upstream Semgrep playground: Nr3z

> Historical/upstream Semgrep example; NOT an OpenGrep compatibility promise. Downloaded 2026-10-03; not executed.

Source: [Nr3z](https://semgrep.dev/embed/editor?snippet=Nr3z). [Raw API response](Nr3z.json).

## Rule definition

```json
{
  "rules": [
    {
      "id": "find-unverified-transactions",
      "patterns": [
        {
          "pattern": "public $RETURN $METHOD(...){\n    ...\n    make_transaction($T);\n    ...\n}\n"
        },
        {
          "pattern-not": "public $RETURN $METHOD(...){\n    ...\n    verify_transaction(...);\n    ...\n    make_transaction(...);\n    ...\n}\n"
        }
      ],
      "message": "In $METHOD, there's a call to make_transaction() without first calling verify_transaction() on the Transaction object.\n",
      "severity": "WARNING",
      "languages": [
        "java"
      ]
    }
  ]
}
```

## Test case 1

```text
public class TransactExample {
    public void base_ok(Transaction t) {
        // OK: verify called before make
        verify_transaction(t);
        make_transaction(t);
    }
    
    public void no_verify(Transaction t) {
        // BAD: transaction isn’t verified
        make_transaction(t);
    }

    public void late_verify(Transaction t){
        // BAD: transaction verified after being made
        make_transaction(t);
        verify_transaction(t);
    }
}
```

Case metadata:

```json
{
  "filename": null,
  "language": "java",
  "highlights": [
    {
      "start": {
        "col": 5,
        "line": 15
      },
      "end": {
        "col": 6,
        "line": 18
      },
      "message": "In no_verify, there's a call to make_transaction() without first calling verify_transaction() on the Transaction object.\n"
    },
    {
      "start": {
        "col": 5,
        "line": 20
      },
      "end": {
        "col": 6,
        "line": 24
      },
      "message": "In late_verify, there's a call to make_transaction() without first calling verify_transaction() on the Transaction object.\n"
    },
    {
      "start": {
        "col": 5,
        "line": 31
      },
      "end": {
        "col": 6,
        "line": 38
      },
      "message": "In other_statements_bad, there's a call to make_transaction() without first calling verify_transaction() on the Transaction object.\n"
    }
  ]
}
```

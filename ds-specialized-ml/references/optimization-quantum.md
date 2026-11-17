# Multi-Objective Optimization & Quantum Circuits: pymoo & PennyLane

Guide to evolutionary single/multi/many-objective optimization (`pymoo==0.6.2`) and differentiable quantum circuits / hybrid QML / VQE / QAOA (`pennylane==0.45.1`).

## Tool Selection

| Need | Tool | Core Strength |
|---|---|---|
| **Single, multi (2–3), or many-objective (4+) optimization** | `pymoo==0.6.2` | NSGA-II/III, MOEA/D, GA/DE/PSO/CMA-ES, constraints (`g<=0`, `h=0`), mixed variables, MCDM |
| **Parameterized quantum circuits, hybrid Torch/JAX QML, VQE, QAOA** | `pennylane==0.45.1` | Device-agnostic QNodes, Autograd/Torch/JAX/Catalyst differentiation, chemistry & QAOA |

*(For hardware-specific gate compilation use Qiskit/Cirq; for open-system master equations use QuTiP.)*

---

## pymoo (`pymoo==0.6.2`, Python 3.10+, NumPy 2.x supported)

```bash
uv pip install "pymoo==0.6.2"   # Optional: joblib (parallel), optuna, dill (checkpoints)
```

### Unified `minimize()` & Result Contract

```python
from pymoo.algorithms.moo.nsga2 import NSGA2
from pymoo.optimize import minimize
from pymoo.problems import get_problem

problem = get_problem("zdt1")
algorithm = NSGA2(pop_size=100)
res = minimize(problem, algorithm, ("n_gen", 200), seed=1, verbose=False)

# res.X (decision vars), res.F (objectives), res.G (ineq g<=0), res.H (eq h=0), res.CV (violation)
```

- **Feasibility check**: `res.X` and `res.F` can be `None` if no feasible solution exists. With `return_least_infeasible=True`, candidates may still violate constraints—check `res.CV` before plotting or selecting.
- **Termination**: Use `("n_gen", N)` or `DefaultMultiObjectiveTermination(ftol=0.001, n_max_gen=100)` (`f_tol` is obsolete).
- **Negate maximization** objectives explicitly and record the conversion.

### Problem Styles & Algorithm Matrix
- **`Problem`**: Vectorized (`_evaluate(self, X, out, *args, **kwargs)` receives batch matrix).
- **`ElementwiseProblem`**: One solution per call—use for custom logic and `elementwise_runner` parallelization (`StarmapParallelization` / `JoblibParallelization`).
- **`FunctionalProblem`**: Define objectives/constraints as functions without subclassing.
- **Mixed-variable**: Pass `vars` dict with typed variables (`Real`, `Integer`, `Binary`, `Choice`).

| Regime | Algorithms | Notes |
|---|---|---|
| **Single-objective** | `GA`, `DE`, `PSO`, `CMAES` | Continuous: `SBX(prob=0.9, eta=15)` + `PM(eta=20)`. Binary: `TwoPointCrossover`/`UniformCrossover` + `BitflipMutation`. Permutation: `OX` + `InversionMutation`. |
| **Multi-objective (2–3)** | `NSGA2`, `SPEA2`, `RNSGA2`, `MOEAD` | `MOEAD` does **not** support constraints directly. |
| **Many-objective (4+)** | `NSGA3`, `RVEA`, `AGEMOEA` | `NSGA3` requires reference directions (`get_reference_directions("das-dennis", n_obj, n_partitions=p)`). Direction count is `C(p + m - 1, m - 1)`—size `pop_size >= n_ref_dirs`. |
| **Heavy constraints** | `SRES`, `ISRES`, or penalty/repair | Formulate inequalities as `g(x) <= 0`. |

- **MCDM**: Normalize objectives (check for constant columns first) before applying `PseudoWeights` or scalarization; `PseudoWeights` matches pseudo-weight vectors, not a weighted sum.

---

## PennyLane (`pennylane==0.45.1`, Python 3.11+, NumPy 2+)

```bash
uv pip install "pennylane==0.45.1"   # Includes Lightning; for JAX pair tested JAX/JAXlib 0.7.1
```

### QNode, Differentiation & Optimization

```python
import pennylane as qml
from pennylane import numpy as np

dev = qml.device("default.qubit", wires=1)

@qml.qnode(dev, interface="autograd", diff_method="backprop")
def energy(theta):
    qml.RY(theta, wires=0)
    return qml.expval(qml.Z(0))

theta = np.array(0.3, requires_grad=True)
grad_val = qml.grad(energy)(theta)

opt = qml.GradientDescentOptimizer(stepsize=0.2)
for _ in range(80):
    theta = opt.step(energy, theta)
final_energy = float(energy(theta))
```

- **Interfaces & tensors**: Use `pennylane.numpy` (`requires_grad=True`) for `interface="autograd"`, native `torch.Tensor` for `"torch"` (`qml.qnn.TorchLayer`), or `jax.numpy` for `"jax"`.
- **Keep quantum function separate from QNode** when reusing across devices/plugins.
- **`step_and_cost`**: Returns `(params_updated, cost_BEFORE_update)`—re-evaluate `energy(theta)` after the loop for final reporting.

### Critical Gotchas (0.45.1)
- **Shots & sampling**: Samples/counts require finite shots; use `qml.set_shots(qnode, shots=1000)` on the QNode instead of mutating device shots.
- **Randomness**: A simulator seed initializes a random stream; successive calls draw new samples. Reconstruct an equally seeded device to reproduce a stream.
- **Mid-circuit measurements**: Values are symbolic—use `qml.cond(m, true_fn, false_fn)`, never Python `if m:`.
- **Resource inspection**: `qml.specs(qnode)(*args)` returns `CircuitSpecs`—access `.resources` (not obsolete top-level dict keys); record the transform `level` and account for split tapes.
- **QAOA MaxCut sign**: `qml.qaoa.maxcut` returns **negative cut size**—minimize it directly.
- **Quantum chemistry**: Geometry defaults to **bohr** (state units explicitly). Unconstrained ansätze can drift outside the target electron/spin sector—verify particle number and compare against a sector-appropriate classical reference.
- **Zero/flat gradients**: Can arise from unused parameters, symmetry, saturated encoding, shot noise, or differentiation failure—do not assume barren plateau without checking analytic/finite-diff gradients on a small circuit first.

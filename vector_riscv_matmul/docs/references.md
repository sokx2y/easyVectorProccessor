# Reference review

## Vicuna

- Repository: https://github.com/vproc/vicuna
- Useful ideas: separate control/decode from the vector datapath, parameterize
  vector structures, and keep simulation collateral beside the RTL.
- Not adopted: complete Zve32x/RVV behavior, coprocessor protocol, pipelined
  hazards, and production-level integration.
- Principle reused: explicit modules with narrow responsibilities and a
  lane-oriented execution block.

## Ara

- Repository: https://github.com/pulp-platform/ara
- Useful ideas: organize vector execution as parallel lanes and keep a clear
  boundary between scalar control and vector state/execution.
- Not adopted: CVA6 integration, complete RVV decode/state, operand queues,
  lane pipelines, arbitration, and high-performance scheduling.
- Principle reused: scalar operands can feed a vector lane array through a
  small, explicit scalar-to-vector operation (`VMAC-s`).

This project is independently implemented for a teaching ISA. The references
informed organization, not instruction encoding or copied RTL.

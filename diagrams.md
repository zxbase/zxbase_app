# Diagrams

## Launch sequence
```mermaid
  graph TD;
      A[main] --> A1[Splash Widget];
      A1 --> B{Vault initiated?};
      B -- No --> C;
      B -- Yes --> D;
      C[Init Vault Widget] --> E;
      D[Open Vault Widget] --> E;
      E[Launch Widget] --> F{Is Mobile?};
      F -- No --> G[Desktop Widget];
      F -- Yes --> H[Explorer Widget];
```

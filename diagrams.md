# Diagrams

## Launch sequence
```mermaid
  graph TD;
      A[main] --> B{Vault initiated?};
      B -- No --> C;
      B -- Yes --> D;
      C[Init Vault Page] --> E;
      D[Open Vault Page] --> E;
      E[Launch Page] --> F{Is Mobile?};
      F -- No --> G[Desktop Page];
      F -- Yes --> H[Mobile Page];
```

# Bug Log & Solutions

This directory serves as a centralized knowledge base for all critical bugs encountered during the development and deployment of the Task Engine.

## Bug Registry

| Bug ID | Title | Module | Date Fixed |
| :--- | :--- | :--- | :--- |
| [001](./001-typeorm-duplicate-index.md) | TypeORM Duplicate Key Name on Sync | Database / TypeORM | Aug 2026 |
| [002](./002-webpack-entity-resolution.md) | Webpack Entity Glob Pattern Resolution Failure | Database / Webpack | Aug 2026 |

## How to add a new bug
1. Create a new markdown file named `XXX-bug-name.md`.
2. Follow the standard template:
   - **Issue Description:** What was happening?
   - **Root Cause:** Why did it happen?
   - **Affected Files:** Where was the fix applied?
   - **Solution:** How was it fixed (include code snippets)?
   - **How to Prevent:** Guidelines for the future.
3. Add an entry to the `Bug Registry` table in this `index.md` file.

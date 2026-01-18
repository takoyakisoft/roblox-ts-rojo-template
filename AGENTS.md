# Roblox-TS Project Guidelines

## Overview

This project is built using [roblox-ts](https://roblox-ts.com/), compiling TypeScript to Luau for Roblox development. It uses [rokit](https://github.com/rojo-rbx/rokit) for tool management (Rojo, Lune).

## Project Structure

- `src/client`: Client-side entry point and code (LocalScripts).
- `src/server`: Server-side entry point and code (Scripts).
- `src/shared`: Shared code (ModuleScripts) accessible by both Client and Server.
- `tests`: Test runner configuration and non-TS test resources.

## Development Workflow

1.  **Install Dependencies**: `pnpm install` & `rokit install`
2.  **Start Compiler**: `pnpm run watch` (Compiles TS -> Luau in real-time)
3.  **Start Sync**: `rokit run rojo serve` (Syncs Luau -> Roblox Studio)
4.  **Lint & Format**: `pnpm run fix` (Runs ESLint and Prettier)
5.  **Run Tests**: `pnpm run test` (Builds and runs TestEZ tests via Lune)

Note: Always ensure `rbxtsc` is running (`pnpm run watch`) during development.

## Coding Standards

### Naming Conventions

- **Files**: `kebab-case` (e.g., `player-data.ts`, `game-manager.ts`).
    - _Exception_: React components can use `PascalCase` (e.g. `InventoryApp.tsx`).
- **classes / Interfaces / Components**: `PascalCase`
- **Functions / Variables**: `camelCase`
- **Constants**: `UPPER_SNAKE_CASE`

### TypeScript & Roblox

- **Services**: Use `@rbxts/services` (e.g., `import { Players } from "@rbxts/services"`).
- **React**: Use `@rbxts/react` and `@rbxts/react-roblox` for UI.
    - Prefer functional components with hooks.
- **Asynchronous**: Use `Promise` (native to roblox-ts).

## Testing

- **Framework**: TestEZ (via `@rbxts/testez`).
- **Location**: Co-locate test files with source files using the `.spec.ts` extension (e.g., `math-utils.ts` -> `math-utils.spec.ts`).
- **Execution**: Tests are compiled and run locally using Lune.

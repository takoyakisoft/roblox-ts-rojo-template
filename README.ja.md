[English](README.md) [日本語](README.ja.md)

![CI](https://github.com/takoyakisoft/roblox-ts-rojo-template/actions/workflows/ci.yml/badge.svg)

# これは何？

Roblox（TypeScript）でVSCodeを使ったモダンな開発環境のテンプレートです。

- VSCode 👉 Roblox Studioへの同期: [Rojo](https://github.com/rojo-rbx/rojo)
- リンター: [ESlint](https://github.com/eslint/eslint)
- フォーマッター: [Prettier](https://github.com/prettier/prettier)
- パッケージマネージャー: [pnpm](https://github.com/pnpm/pnpm)

> [!CAUTION]
> 動作未確認ですが、有名なパッケージを入れてあります。

- "@rbxts/profileservice"
- "@rbxts/testez"

> [!NOTE]
> 動作確認済

- "@rbxts/react"
- "@rbxts/react-roblox"

# インストール

> [!TIP]
> "Use this template"ボタンから使えます。

## パッケージのインストール

```bash
pnpm install
```

## VSCode拡張機能のインストール

このプロジェクトを開くとVSCodeで以下の拡張機能が表示されるのでインストールします。

- [roblox-ts](https://marketplace.visualstudio.com/items?itemName=Roblox-TS.vscode-roblox-ts)
- [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)
- [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
- [Rojo](https://marketplace.visualstudio.com/items?itemName=evaera.vscode-rojo)

# 使い方

## VSCodeからRojo

```bash
pnpm run watch
```

「Ctrl + Shift + P」

「Rojo: Open Menu」

> [!NOTE]
> 初めてならRoblox Studioを起動して、Install Roblox Studio Plugin

「▶ default.project.json」

## Roblox StudioからRojo

「プラグイン」タブ

「Rojo」リボン

「Connect」ボタン

# テスト

このプロジェクトでは、[TestEZ](https://github.com/Roblox/testez) と [Lune](https://github.com/lune-org/lune) を使用した自動テストを導入しています。

> [!NOTE]
> CI環境でのテストは、LuneとAIによって生成されたRoblox APIモックを使用して実行されます。これは主に、Roblox Studio外での基本的なロジックの動作確認を目的としたものです。

## テストの実行

```bash
pnpm run test
```

import js from "@eslint/js";
import tseslint from "typescript-eslint";
import roblox from "eslint-plugin-roblox-ts";
import prettierConfig from "eslint-config-prettier";
import prettierPlugin from "eslint-plugin-prettier";

export default[
  { ignores: ["out/**", "node_modules/**"] },

  js.configs.recommended,

  ...tseslint.configs.recommended,

  {
    rules: {
      ...prettierConfig.rules,
    },
  },

  {
    files: ["src/**/*.ts", "src/**/*.tsx"],

    plugins: {
      "roblox-ts": roblox,
      "prettier": prettierPlugin,
    },

    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {
        project: true,
        sourceType: "module",
        jsx: true,
      },
    },

    rules: {
      ...roblox.configs.recommended.rules,

      "prettier/prettier": "warn",

      "roblox-ts/no-any": ["error", { fixToUnknown: true }],
      "roblox-ts/no-null": "error",
      "roblox-ts/no-object-math": "error",

      "@typescript-eslint/no-explicit-any": "off",
    },
  },
];

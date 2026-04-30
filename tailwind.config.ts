import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        cream: "#F5EFE8",
        warmBlack: "#0D0C0A",
        terracotta: "#C45E42",
        rose: "#B89A9A",
        moss: "#3D5C3A"
      }
    }
  },
  plugins: []
};

export default config;

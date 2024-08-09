import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: "#F1F5F9", // Light background
        secondary: "#ffffff", // Card background
        accent: "#5b21b6", // Primary accent color (purple)
        highlight: "#a78bfa", // Lighter accent color (lavender)
      },
      boxShadow: {
        custom: "0px 0px 24px rgba(167, 38, 169, 0.66)", // Custom box shadow to match the image
      },
      backgroundImage: {
        "custom-gradient": "linear-gradient(135deg, #ffffff 0%, #e5e7eb 100%)", // Custom gradient for a soft effect
      },
    },
  },
  plugins: [],
};
export default config;

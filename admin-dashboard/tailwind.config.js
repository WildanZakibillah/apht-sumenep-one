/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: "class",
  theme: {
      extend: {
          "colors": {
              "surface": "#fbf8ff",
              "secondary-fixed": "#d9e2ff",
              "on-tertiary": "#ffffff",
              "on-primary-fixed-variant": "#343d96",
              "on-background": "#1b1b21",
              "surface-container-high": "#eae7ef",
              "surface-container-low": "#f5f2fb",
              "on-primary": "#ffffff",
              "on-secondary-container": "#00337c",
              "surface-container": "#efecf5",
              "inverse-surface": "#303036",
              "primary-fixed-dim": "#bdc2ff",
              "on-secondary": "#ffffff",
              "outline": "#767683",
              "error-container": "#ffdad6",
              "on-surface": "#1b1b21",
              "surface-container-lowest": "#ffffff",
              "inverse-on-surface": "#f2eff8",
              "surface-variant": "#e4e1ea",
              "on-tertiary-fixed-variant": "#7b2e12",
              "tertiary-container": "#5c1800",
              "outline-variant": "#c6c5d4",
              "on-tertiary-fixed": "#390c00",
              "on-error": "#ffffff",
              "primary": "#000666",
              "background": "#fbf8ff",
              "secondary-fixed-dim": "#b0c6ff",
              "error": "#ba1a1a",
              "tertiary-fixed": "#ffdbd0",
              "surface-dim": "#dbd9e1",
              "on-primary-fixed": "#000767",
              "on-secondary-fixed": "#001945",
              "secondary": "#2b5bb5",
              "primary-fixed": "#e0e0ff",
              "surface-container-highest": "#e4e1ea",
              "surface-tint": "#4c56af",
              "tertiary": "#380b00",
              "on-error-container": "#93000a",
              "tertiary-fixed-dim": "#ffb59d",
              "on-primary-container": "#8690ee",
              "primary-container": "#1a237e",
              "on-secondary-fixed-variant": "#00429c",
              "secondary-container": "#759efd",
              "surface-bright": "#fbf8ff",
              "inverse-primary": "#bdc2ff",
              "on-tertiary-container": "#e17c5a",
              "on-surface-variant": "#454652"
          },
          "borderRadius": {
              "DEFAULT": "0.125rem",
              "lg": "0.25rem",
              "xl": "0.5rem",
              "full": "0.75rem"
          },
          "spacing": {
              "sm": "12px",
              "base": "8px",
              "sidebar-width": "280px",
              "xs": "4px",
              "xl": "48px",
              "lg": "32px",
              "md": "24px",
              "container-max": "1440px"
          },
          "fontFamily": {
              "h1": ["Inter", "sans-serif"],
              "body-md": ["Inter", "sans-serif"],
              "label-sm": ["Inter", "sans-serif"],
              "h3": ["Inter", "sans-serif"],
              "body-lg": ["Inter", "sans-serif"],
              "h2": ["Inter", "sans-serif"],
              "mono": ["Inter", "monospace"]
          },
          "fontSize": {
              "h1": ["32px", { "lineHeight": "1.2", "letterSpacing": "-0.02em", "fontWeight": "700" }],
              "body-md": ["14px", { "lineHeight": "1.5", "letterSpacing": "0", "fontWeight": "400" }],
              "label-sm": ["12px", { "lineHeight": "1", "letterSpacing": "0.02em", "fontWeight": "500" }],
              "h3": ["20px", { "lineHeight": "1.4", "letterSpacing": "0", "fontWeight": "600" }],
              "body-lg": ["16px", { "lineHeight": "1.6", "letterSpacing": "0", "fontWeight": "400" }],
              "h2": ["24px", { "lineHeight": "1.3", "letterSpacing": "-0.01em", "fontWeight": "600" }],
              "mono": ["13px", { "lineHeight": "1.5", "letterSpacing": "0", "fontWeight": "400" }]
          }
      }
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/container-queries')
  ],
}

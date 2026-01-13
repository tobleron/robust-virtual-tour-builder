/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [
        "./src/**/*.{html,js,jsx,ts,tsx,res,bs.js}",
        "./*.html"
    ],
    theme: {
        extend: {
            colors: {
                "remax-blue": "#003da5",
                "primary": "#003da5",
                "primary-dark": "#002a70",
            },
            fontFamily: {
                sans: ['Inter', 'ui-sans-serif', 'system-ui'],
                heading: ['Outfit', 'ui-sans-serif', 'system-ui'],
            }
        },
    },
    plugins: [],
}

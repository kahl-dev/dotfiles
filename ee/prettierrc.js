// prettier.config.js or .prettierrc.js
module.exports = {
  semi: false,
  singleQuote: true,
  trailingComma: 'es5',
  jsxBracketSameLine: true,
  overrides: [
    {
      files: ['*.js'],
      options: {
        printWidth: 80,
      },
    },
    {
      files: ['*.html'],
      options: {
        printWidth: 140,
      },
    },
  ],
}

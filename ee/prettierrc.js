module.exports = {
  printWidth: 100,
  semi: false,
  singleQuote: true,
  trailingComma: 'es5',
  jsxBracketSameLine: true,
  overrides: [
    {
      files: ['*.html'],
      options: {
        printWidth: 140,
      },
    },
  ],
}

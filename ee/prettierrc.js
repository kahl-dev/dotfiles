module.exports = {
  printWidth: 100,
  semi: false,
  singleQuote: true,
  trailingComma: 'es5',
  bracketSameLine: true,
  overrides: [
    {
      files: ['*.html'],
      options: {
        printWidth: 140,
      },
    },
  ],
}


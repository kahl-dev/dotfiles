module.exports = {
  env: {
    es6: true,
    browser: true,
    node: true,
  },
  parserOptions: {
    parser: 'babel-eslint',
    sourceType: 'module',
  },
  extends: ['plugin:prettier/recommended'],
  // required to lint *.vue files
  plugins: ['prettier'],
  // add your custom rules here
}

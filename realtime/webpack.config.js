const path = require('path')
const webpack = require('webpack')
module.exports = {
  mode: 'development',
  entry: './test5.js',
  output: {
    path: path.resolve(__dirname, 'build'),
    libraryTarget: 'commonjs',
    filename: 'app.bundle.js',
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        loader: 'babel-loader',
      },
    ],
  },
  stats: {
    colors: true,
  },
  resolve: {
    alias: {
      websocket: path.resolve(__dirname, 'node_modules/websocket/index.js'),
      bufferutil: path.resolve(__dirname, 'node_modules/bufferutil/fallback.js'),
      'utf-8-validate': path.resolve(__dirname, 'node_modules/utf-8-validate/fallback.js'),
    },
  },
  target: 'web',
  externals: /k6(\/.*)?/,
  devtool: 'source-map',
}

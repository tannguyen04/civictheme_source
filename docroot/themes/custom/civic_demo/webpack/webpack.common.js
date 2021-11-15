const path = require('path');
const glob = require('glob');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const magicImporter = require('node-sass-magic-importer');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = {
  entry: (function (pattern) {
    // Scan for all JS.
    const entries = glob.sync(pattern);
    // Add explicitly imported entries from components.
    entries.push(path.resolve(__dirname, 'components_css.js'));
    // Add explicitly imported entries from the current theme.
    entries.push(path.resolve(__dirname, 'theme_js.js'));
    entries.push(path.resolve(__dirname, 'theme_css.js'));
    entries.push(path.resolve(__dirname, 'fonts.js'));
    return entries;
  }(path.resolve(__dirname, '../components-combined/**/!(*.stories|*.component|*.min|*.test|*.script|*.utils).js'))),
  output: {
    filename: 'scripts.js',
    path: path.resolve(__dirname, '../dist'),
  },
  plugins: [
    new MiniCssExtractPlugin({
      filename: '../dist/styles.css',
    }),
    new CleanWebpackPlugin(),
  ],
  module: {
    rules: [
      // JS Loader.
      {
        test: /^(?!.*\.(stories|component)\.js$).*\.js$/,
        exclude: /node_modules/,
        loader: 'babel-loader',
      },
      // CSS Loader.
      {
        test: /\.s[ac]ss$/i,
        exclude: /node_modules/,
        use: [
          MiniCssExtractPlugin.loader,
          {
            loader: 'css-loader',
            options: {
              sourceMap: true,
              url: false,
            },
          },
          {
            loader: 'sass-loader',
            options: {
              sourceMap: true,
              sassOptions: {
                importer: magicImporter(),
              },
            },
          },
        ],
      },
      // File loader (for fonts).
      // File loader (for fonts).
      {
        test: /\.(woff|woff2|ttf|eot)$/,
        use: {
          loader: 'file-loader',
          options: {
            name: '[name].[ext]',
            // Preserve relative path.
            outputPath: (url, resourcePath, context) => path.relative(context, resourcePath),
          },
        },
      },
      // Twig loader.
      {
        test: /\.twig$/,
        use: [{
          loader: 'twigjs-loader',
        }],
      },
      // Wrap JS into Drupal.behaviours.
      {
        test: /components-combined\/[^/]+\/(?!.*\.(stories|component|utils)\.js$).*\.js$/,
        exclude: /(node_modules|webpack|themejs\.js|css\.js)/,
        use: [{
          loader: 'babel-loader',
          options: {
            presets: [
              '@babel/preset-env',
            ],
            plugins: [
              './node_modules/babel-plugin-syntax-dynamic-import',
              './node_modules/babel-plugin-drupal-behaviors',
            ],
          },
        }],
      },
    ],
  },
  resolve: {
    alias: {
      '@base': path.resolve(__dirname, '../components-combined/00-base'),
      '@atoms': path.resolve(__dirname, '../components-combined/01-atoms'),
      '@molecules': path.resolve(__dirname, '../components-combined/02-molecules'),
      '@organisms': path.resolve(__dirname, '../components-combined/03-organisms'),
      '@templates': path.resolve(__dirname, '../components-combined/04-templates'),
      '@pages': path.resolve(__dirname, '../components-combined/05-pages'),
      '@civic-base': path.resolve(__dirname, '../.components-civic/00-base'),
      '@civic-atoms': path.resolve(__dirname, '../.components-civic/01-atoms'),
      '@civic-molecules': path.resolve(__dirname, '../.components-civic/02-molecules'),
      '@civic-organisms': path.resolve(__dirname, '../.components-civic/03-organisms'),
      '@civic-templates': path.resolve(__dirname, '../.components-civic/04-templates'),
      '@civic-pages': path.resolve(__dirname, '../.components-civic/05-pages'),
    },
  },
  stats: {
    errorDetails: true,
  },
};

// Generated by Finicky Kickstart
// https://github.com/johnste/finicky
// https://finicky-kickstart.now.sh/
// Save as ~/.finicky.js

module.exports = {
  defaultBrowser: 'Brave Browser',
  options: {
    // Hide the finicky icon from the top bar. Default: false
    hideIcon: false,
    // Check for update on startup. Default: true
    checkForUpdate: true,
    // Change the internal list of url shortener services. Default: undefined
    // urlShorteners: (list) => [...list, "custom.urlshortener.com"],
    // Log every request with basic information to console. Default: false
    logRequests: false,
  },
  handlers: [
    {
      match: '*.typo3.dev.louis.info*',
      browser: 'Brave Browser',
    },

    // Open Microsoft Teams links in the native app
    {
      match: finicky.matchHostnames(['teams.microsoft.com']),
      browser: 'com.microsoft.teams',
      url({ url }) {
        return {
          ...url,
          protocol: 'msteams',
        }
      },
    },

    // Open Apple Music links in the Music apps
    {
      match: ['music.apple.com*', 'geo.music.apple.com*'],
      url: {
        protocol: 'itmss',
      },
      browser: 'Music',
    },

    {
      // Open links in Safari when the option key is pressed
      // Valid keys are: shift, option, command, control, capsLock, and function.
      // Please note that control usually opens a tooltip menu instead of visiting a link
      match: () => finicky.getKeys().option,
      browser: 'Safari',
    },
  ],

  rewrite: [
    // Remove all marketing/tracking information from urls
    {
      match: () => true, // Execute rewrite on all incoming urls to make this example easier to understand
      url({ url }) {
        const removeKeysStartingWith = ['utm_', 'uta_'] // Remove all query parameters beginning with these strings
        const removeKeys = ['fblid', 'gclid'] // Remove all query parameters matching these keys

        const search = url.search
          .split('&')
          .map((parameter) => parameter.split('='))
          .filter(
            ([key]) => !removeKeysStartingWith.some((startingWith) => key.startsWith(startingWith))
          )
          .filter(([key]) => !removeKeys.some((removeKey) => key === removeKey))

        return {
          ...url,
          search: search.map((parameter) => parameter.join('=')).join('&'),
        }
      },
    },
    // {
    //   match: ({ url }) => url.host.endsWith('twitter.com'),
    //   url: ({ url, urlString }) => {
    //     return {
    //       ...url,
    //       host: '',
    //       protocol: 'tweetbot',
    //       pathname: url.pathname.replace(/^\/+/g, ''),
    //     }
    //   },
    // },
  ],
}

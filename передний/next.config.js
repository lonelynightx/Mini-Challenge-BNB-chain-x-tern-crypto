
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  webpack: (config, options) => {
    config.module.rules.push({
      test: /\.node$/,
      use: 'raw-loader'
    })
    return config
  },
}

module.exports = nextConfig

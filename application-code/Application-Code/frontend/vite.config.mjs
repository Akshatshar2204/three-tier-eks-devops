import { defineConfig, transformWithOxc } from 'vite';
import react from '@vitejs/plugin-react';

function transformJsxInJs() {
  return {
    name: 'transform-jsx-in-js',
    enforce: 'pre',

    async transform(code, id) {
      const file = id.split('?')[0];

      // Parse JSX in JavaScript files under src/.
      if (!/\/src\/.*\.js$/.test(file)) {
        return null;
      }

      return transformWithOxc(code, file, {
        lang: 'jsx',
      });
    },
  };
}

export default defineConfig({
  plugins: [
    react(),
    transformJsxInJs(),
  ],
});

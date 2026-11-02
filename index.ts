type ElmPagesInit = {
  load: (elmLoaded: Promise<unknown>) => Promise<void>;
  flags: unknown;
};

const config: ElmPagesInit = {
  load: async function (elmLoaded) {
    await elmLoaded;
  },
  // Shared.elm decodes these. The atlas aligns its drawing to device pixels.
  flags: function () {
    return { pixelRatio: window.devicePixelRatio || 1 };
  },
};

export default config;

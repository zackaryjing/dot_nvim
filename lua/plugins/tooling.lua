return {
  {
    "mason-org/mason.nvim",
    opts = {
      -- Prefer system and ~/.local tools when Mason downloaded a binary that
      -- is incompatible with the host (for example a newer GLIBC on Debian).
      PATH = "append",
    },
  },
}

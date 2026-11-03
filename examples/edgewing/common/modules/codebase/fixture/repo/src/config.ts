/**
 * Configuration: where the lamps are and how the service listens.
 */
import { readFileSync } from "node:fs";
import type { Lamp } from "./lamp";

/** The port the service listens on when none is configured. */
export const DEFAULT_PORT = 8080;

/** What the service reads at start. */
export interface Config {
  /** The port to listen on. */
  port: number;
  lamps: Lamp[];
  /** A greeting, e.g. for the status page. Never secret. */
  greeting?: string;
}

/**
 * Reads the configuration file and fills the defaults. The file must be JSON.
 * @param path where the file is
 */
export function loadConfig(path: string = "lantern.json"): Config {
  const raw = JSON.parse(readFileSync(path, "utf8"));
  const port = Number(process.env.LANTERN_PORT ?? raw.port ?? DEFAULT_PORT);
  return { port, lamps: raw.lamps ?? [], greeting: process.env["LANTERN_GREETING"] };
}

/** Raised when the configuration cannot be read. */
export class ConfigError extends Error {
  readonly path: string;
  private attempts = 0;

  constructor(path: string, message: string) {
    super(message);
    this.path = path;
  }

  /** A one-line description for the log. */
  describe(): string {
    return `${this.path}: ${this.message}`;
  }
}

const secretPattern = /\{[a-z]+\}/;

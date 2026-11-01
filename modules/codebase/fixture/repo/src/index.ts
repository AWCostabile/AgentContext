#!/usr/bin/env node
/**
 * Lantern: a small service that keeps a board of lamps.
 */

export { loadConfig, ConfigError } from "./config";
export * from "./lamp";

/** Starts the service. */
export default async function main(): Promise<void> {
  const { loadConfig } = await import("./config");
  const config = loadConfig();
  console.log(`listening on ${config.port}`);
}

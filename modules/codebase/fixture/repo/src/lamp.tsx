import React from "react";

/** How bright a lamp burns. */
export enum Brightness {
  Dim,
  Bright,
}

/** One lamp on the board. */
export type Lamp = {
  id: string;
  brightness: Brightness;
};

/** Draws one lamp. */
function LampView(props: { lamp: Lamp }) {
  return <span className="lamp">{props.lamp.id}</span>;
}

/** Turns a lamp up one step. */
const brighten = (lamp: Lamp): Lamp => ({ ...lamp, brightness: Brightness.Bright });

export { LampView, brighten as raise };

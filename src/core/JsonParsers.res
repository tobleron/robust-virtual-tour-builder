/* src/core/JsonParsers.res */
/* @efficiency-role: data-model */

// Re-export shared parsers
module Shared = JsonParsersShared

// Re-export decoders and encoders from split modules for backward compatibility
module Domain = JsonParsersDecoders
module Encoders = JsonParsersEncoders

/* src/systems/BackendApi.res */

/**
 * FACADE MODULE
 * 
 * Logic has been split into:
 * - src/systems/api/ApiTypes.res (Types & Decoders)
 * - src/systems/api/ProjectApi.res (Project & Navigation)
 * - src/systems/api/MediaApi.res (Media & Processing)
 */
include ApiTypes
include ProjectApi
include MediaApi

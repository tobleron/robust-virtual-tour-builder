/* src/systems/Api.res - Consolidated API module */

/* Logic extracted to ApiLogic.res to reduce bloat */
include ApiLogic

/* Re-export contents for backward compatibility */
include ApiTypes
include AuthenticatedClient
include MediaApi
include ProjectApi

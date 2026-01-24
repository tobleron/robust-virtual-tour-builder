export async function resolve(specifier, context, nextResolve) {
  if (specifier.endsWith('.jsx')) {
    return {
      shortCircuit: true,
      url: `data:text/javascript,export const Button = ({children}) => children; export const Popover = ({children}) => children; export const PopoverTrigger = ({children}) => children; export const PopoverContent = ({children}) => children; export const PopoverAnchor = ({children}) => children; export const Tooltip = ({children}) => children; export const TooltipProvider = ({children}) => children; export const TooltipTrigger = ({children}) => children; export const TooltipContent = ({children}) => children; export const DropdownMenu = ({children}) => children; export const DropdownMenuTrigger = ({children}) => children; export const DropdownMenuContent = ({children}) => children; export const DropdownMenuItem = ({children}) => children; export const DropdownMenuSeparator = () => () => null; export const ContextMenu = ({children}) => children; export const ContextMenuTrigger = ({children}) => children; export const ContextMenuContent = ({children}) => children; export const ContextMenuItem = ({children}) => children; export const ContextMenuSeparator = () => () => null;`
    };
  }
  return nextResolve(specifier, context);
}

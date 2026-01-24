"use client"

import { Toaster as Sonner } from "sonner"

const Toaster = ({ visibleToasts = 3, duration = 4000, ...props }) => {
    return (
        (<Sonner
            expand={true}
            duration={duration}
            visibleToasts={visibleToasts}
            className="vtb-toaster-root"
            toastOptions={{
                classNames: {
                    toast:
                        "group toast group-[.vtb-toaster-root]:bg-[#0e2d52] group-[.vtb-toaster-root]:backdrop-blur-[8px] group-[.vtb-toaster-root]:text-white group-[.vtb-toaster-root]:border-none group-[.vtb-toaster-root]:shadow-none group-[.vtb-toaster-root]:py-2.5 group-[.vtb-toaster-root]:px-4 group-[.vtb-toaster-root]:text-[13px] group-[.vtb-toaster-root]:rounded-md group-[.vtb-toaster-root]:min-w-[360px] group-[.vtb-toaster-root]:max-w-[360px] group-[.vtb-toaster-root]:h-[42px] font-medium",
                    description: "group-[.toast]:text-slate-400 group-[.toast]:text-[8px]",
                    actionButton:
                        "group-[.toast]:bg-[var(--primary)] group-[.toast]:text-white group-[.toast]:text-[8px] group-[.toast]:px-1.5 group-[.toast]:h-5",
                    cancelButton:
                        "group-[.toast]:bg-slate-700 group-[.toast]:text-slate-300 group-[.toast]:text-[8px] group-[.toast]:px-1.5 group-[.toast]:h-5",
                    success: "group-[.vtb-toaster-root]:!bg-[#059669]",
                    error: "group-[.vtb-toaster-root]:!bg-[#ea580c]",
                    warning: "group-[.vtb-toaster-root]:!bg-[#f59e0b]",
                    info: "group-[.vtb-toaster-root]:!bg-[#0e2d52]",
                },
            }}
            {...props} />)
    );
}

export { Toaster }

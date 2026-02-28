@react.component
let make = () => {
  <div className="flex flex-col gap-3 mt-2 items-center w-full">
    <div className="flex flex-col gap-1 items-center text-center">
      <p className="text-white font-semibold font-mono text-[11px]">
        {React.string(`Version: ${Version.getVersionLabel()}`)}
      </p>
      <p className="text-slate-300 font-mono text-[10px]">
        {React.string(`Build: ${Version.getBuildInfo()}`)}
      </p>
    </div>
  </div>
}

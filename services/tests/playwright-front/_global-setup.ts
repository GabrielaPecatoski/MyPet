import { execSync } from "node:child_process";

const ps = (cmd: string) => {
  try {
    execSync(`powershell -NoProfile -Command "${cmd}"`, { stdio: "pipe" });
  } catch {}
};

async function responds(url: string, timeoutMs: number): Promise<boolean> {
  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(timeoutMs) });
    return res.status > 0;
  } catch {
    return false;
  }
}

function killListenerOnPort(port: number, onlyProcessName?: string) {
  const filter = onlyProcessName
    ? ` | Where-Object { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName -eq '${onlyProcessName}' }`
    : "";
  ps(
    `Get-NetTCPConnection -LocalPort ${port} -State Listen -ErrorAction SilentlyContinue${filter}` +
      " | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -Confirm:0 }",
  );
}

export default async function globalSetup() {
  if (!(await responds("http://localhost/faq", 6000))) {
    console.log(
      "[global-setup] http://localhost mudo — matando wslrelay zumbi em ::1:80...",
    );
    killListenerOnPort(80, "wslrelay");
    if (await responds("http://localhost/faq", 6000)) {
      console.log("[global-setup] localhost recuperado.");
    } else {
      console.warn(
        "[global-setup] http://localhost segue inacessível — stack fora do ar? (docker compose ps / scripts/fix-localhost.ps1)",
      );
    }
  }

  if (!(await responds("http://localhost:8080/index.html", 4000))) {
    console.log(
      "[global-setup] :8080 ocupada/sem resposta — limpando para o webServer...",
    );
    killListenerOnPort(8080);
  }
}

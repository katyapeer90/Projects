const projects = [
  {
    no: '01', label: 'TERRAFORM / AZURE', title: 'Multi-Environment AKS Platform',
    summary: 'Reusable Infrastructure-as-Code for provisioning and managing Azure Kubernetes environments across development and production workloads.',
    tags: ['Terraform', 'Azure', 'AKS', 'Kubernetes', 'ACR'],
    details: ['Reusable Terraform modules', 'Environment-specific configuration', 'AKS node pools & autoscaling', 'ACR and networking integration'],
    href: 'https://github.com/katyapeer90/Projects/tree/main/Terraform'
  },
  {
    no: '02', label: 'CI/CD / PLATFORM', title: 'CI/CD & Kubernetes Release Platform',
    summary: 'Delivery workflows covering application builds, container publishing, release management and Kubernetes deployments across multiple environments.',
    tags: ['Jenkins', 'Groovy', 'Docker', 'Helm', 'Kubernetes'],
    details: ['Build and deployment pipelines', 'Container publishing', 'Helm release management', 'Environment promotion workflows'],
    href: 'https://github.com/katyapeer90/Projects/tree/main/Jenkins'
  },
  {
    no: '03', label: 'AUTOMATION / GITHUB', title: 'WordPress Core Update Automation',
    summary: 'Event-driven automation connecting WordPress core updates to the container build and deployment lifecycle through GitHub Actions.',
    tags: ['GitHub Actions', 'Docker', 'PHP', 'WordPress', 'CI/CD'],
    details: ['WordPress update event detection', 'Repository dispatch workflow', 'Automated Dockerfile updates', 'Integration with the normal delivery lifecycle'],
    href: 'https://github.com/katyapeer90/Projects/tree/main/WP'
  }
]

const Arrow = () => <span aria-hidden="true">↗</span>

function App() {
  return <div className="min-h-screen grid-bg">
    <header className="sticky top-0 z-20 border-b border-black/10 bg-[#f7f7f4]/90 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-6 py-4">
        <a href="#top" className="text-lg font-black tracking-tight">KP<span className="text-blue-700">.</span></a>
        <nav className="flex gap-5 text-sm font-medium text-neutral-600">
          <a className="hover:text-black" href="#projects">Projects</a><a className="hover:text-black" href="#experience">Experience</a><a className="hover:text-black" href="#about">About</a>
        </nav>
      </div>
    </header>

    <main id="top">
      <section className="mx-auto max-w-6xl px-6 pb-24 pt-24 md:pb-32 md:pt-32">
        <div className="mono mb-6 text-xs font-bold tracking-[.22em] text-blue-700">DEVOPS ENGINEER</div>
        <h1 className="max-w-4xl text-5xl font-black leading-[.96] tracking-[-.055em] md:text-8xl">Infrastructure.<br/>Automation.<br/><span className="text-neutral-400">Reliability.</span></h1>
        <p className="mt-8 max-w-2xl text-lg leading-8 text-neutral-600 md:text-xl">I'm Katya Peer, a DevOps Engineer building and supporting reliable infrastructure, delivery platforms and automation across cloud and production environments.</p>
        <div className="mt-9 flex flex-wrap gap-3">
          <a href="#projects" className="rounded-full bg-neutral-950 px-6 py-3 text-sm font-bold text-white hover:bg-blue-700">Explore projects ↓</a>
          <a href={`${import.meta.env.BASE_URL}Katya-Peer-CV.pdf`} target="_blank" className="rounded-full border border-black/20 bg-white/60 px-6 py-3 text-sm font-bold hover:border-black">View CV ↗</a>
          <a href="https://github.com/katyapeer90" target="_blank" className="rounded-full px-5 py-3 text-sm font-bold text-neutral-600 hover:text-black">GitHub <Arrow /></a>
        </div>
      </section>

      <section id="projects" className="border-y border-black/10 bg-[#efefeb]/75">
        <div className="mx-auto max-w-6xl px-6 py-24">
          <div className="mb-12 flex items-end justify-between"><div><div className="mono text-xs font-bold tracking-[.2em] text-blue-700">SELECTED WORK</div><h2 className="mt-3 text-4xl font-black tracking-tight">Engineering projects</h2></div><span className="hidden text-sm text-neutral-500 md:block">03 case studies</span></div>
          <div className="space-y-4">
            {projects.map(p => <article key={p.no} className="group rounded-2xl border border-black/10 bg-[#f7f7f4] p-6 transition hover:-translate-y-0.5 hover:border-black/25 md:p-9">
              <div className="grid gap-7 md:grid-cols-[90px_1fr_280px]">
                <div><div className="mono text-3xl font-bold text-neutral-300">{p.no}</div><div className="mono mt-2 text-[10px] font-bold tracking-wider text-blue-700">{p.label}</div></div>
                <div><h3 className="text-2xl font-black tracking-tight md:text-3xl">{p.title}</h3><p className="mt-4 max-w-2xl leading-7 text-neutral-600">{p.summary}</p><div className="mt-5 flex flex-wrap gap-2">{p.tags.map(t => <span key={t} className="mono rounded-md border border-black/10 bg-white/60 px-2.5 py-1 text-xs">{t}</span>)}</div></div>
                <div className="flex flex-col justify-between border-t border-black/10 pt-5 md:border-l md:border-t-0 md:pl-7 md:pt-0"><ul className="space-y-2 text-sm text-neutral-600">{p.details.map(d => <li key={d}>— {d}</li>)}</ul><a className="mt-7 text-sm font-bold text-blue-700 hover:text-blue-900" href={p.href} target="_blank">View source <Arrow /></a></div>
              </div>
            </article>)}
          </div>
        </div>
      </section>

      <section id="experience" className="mx-auto max-w-6xl px-6 py-24">
        <div className="mono text-xs font-bold tracking-[.2em] text-blue-700">EXPERIENCE</div><h2 className="mt-3 text-4xl font-black tracking-tight">Where I've worked</h2>
        <div className="mt-12 divide-y divide-black/10 border-y border-black/10">
          <div className="grid gap-4 py-8 md:grid-cols-[190px_260px_1fr]"><div className="mono text-sm text-neutral-500">2022 — PRESENT</div><div><div className="font-black">DevOps Engineer</div><div className="text-neutral-500">Tricky Tech</div></div><p className="max-w-xl leading-7 text-neutral-600">SRE, CI/CD, Infrastructure-as-Code and platform automation services across multiple client projects and environments.</p></div>
          <div className="grid gap-4 py-8 md:grid-cols-[190px_260px_1fr]"><div className="mono text-sm text-neutral-500">2017 — 2022</div><div><div className="font-black">IT Manager</div><div className="text-neutral-500">Guberman Group</div></div><p className="max-w-xl leading-7 text-neutral-600">IT operations, networks, systems, security, troubleshooting, migrations and infrastructure reliability across business-critical systems.</p></div>
        </div>
      </section>

      <section id="about" className="border-y border-black/10 bg-neutral-950 text-white">
        <div className="mx-auto grid max-w-6xl gap-12 px-6 py-24 md:grid-cols-2">
          <div><div className="mono text-xs font-bold tracking-[.2em] text-blue-300">ABOUT</div><h2 className="mt-4 text-4xl font-black tracking-tight">I like making complex systems simpler to operate.</h2><p className="mt-6 leading-7 text-neutral-300">My background spans infrastructure, operations and automation. I work across unfamiliar environments, learn the systems quickly, and build practical solutions that improve delivery and reliability.</p></div>
          <div className="grid grid-cols-2 gap-x-8 gap-y-7 text-sm"><Tech title="Infrastructure" items="Terraform · Kubernetes · Helm · Docker"/><Tech title="CI/CD" items="Jenkins · Git · GitHub Actions"/><Tech title="Cloud" items="Azure · AWS"/><Tech title="Engineering" items="Linux · Groovy · YAML · SRE"/></div>
        </div>
      </section>
    </main>

    <footer className="mx-auto flex max-w-6xl flex-col gap-5 px-6 py-10 text-sm text-neutral-500 md:flex-row md:items-center md:justify-between"><div>© 2026 Katya Peer</div><div className="flex gap-5"><a className="hover:text-black" href="https://github.com/katyapeer90" target="_blank">GitHub ↗</a><a className="hover:text-black" href="mailto:Katep3061@gmail.com">Email ↗</a></div></footer>
  </div>
}

function Tech({title, items}:{title:string, items:string}) { return <div><div className="mono mb-2 text-[11px] font-bold uppercase tracking-wider text-neutral-500">{title}</div><div className="leading-6 text-neutral-200">{items}</div></div> }
export default App

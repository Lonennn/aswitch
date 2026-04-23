///|
/// Print all supported agents, grouped by installation status
pub fn list_agents() -> Int {
  let agents = @agent.supported_agents()

  // Split into installed and not installed
  let installed : Array[String] = []
  let not_installed : Array[String] = []

  for agent in agents {
    if @agent.is_agent_installed(agent) {
      installed.push(agent)
    } else {
      not_installed.push(agent)
    }
  }

  // Print output based on counts
  if installed.length() == 0 {
    println("No installed agents found")
  } else if installed.length() == agents.length() {
    println("All supported agents are installed:")
    for agent in installed {
      println("  ✓ \{agent}")
    }
  } else {
    println("Installed agents:")
    for agent in installed {
      println("  ✓ \{agent}")
    }
  }

  // Print available agents section if there are any not installed
  if not_installed.length() > 0 {
    if installed.length() > 0 {
      println("") // Add blank line between sections
    }
    let header = if installed.length() == 0 {
      "Available agents:"
    } else {
      "Available agents (not installed):"
    }
    println(header)
    for agent in not_installed {
      println("  - \{agent}")
    }
  }

  // Print summary
  let installed_count = installed.length()
  let total_count = agents.length()
  println("")
  if installed_count == 0 {
    println("Total: \{total_count} agent(s)")
  } else {
    println("Total: \{total_count} agent(s) (\{installed_count} installed)")
  }

  EXIT_CODE_SUCCESS
}

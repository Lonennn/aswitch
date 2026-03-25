///|
/// Print all supported agents
pub fn list_agents() -> Int {
  let agents = @agent.supported_agents()
  println("Supported agents:")
  for agent in agents {
    println("    \{agent}")
  }
  println("\nTotal: \{agents.length()} agent(s)")
  EXIT_CODE_SUCCESS
}

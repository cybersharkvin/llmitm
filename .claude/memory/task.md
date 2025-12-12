{
  "task": "Initialize git repository with proper structure and gitignore",
  "objectives": [
    "Create .gitignore file with appropriate exclusions",
    "Initialize git repository",
    "Create initial commit"
  ],
  "dependencies": {
    "prerequisites": [
      "None - fresh git initialization"
    ],
    "sequential": [
      "Create .gitignore file",
      "Initialize git repo",
      "Stage all files",
      "Create initial commit"
    ],
    "parallel": []
  },
  "atomic_actions": [
    {
      "step": 1,
      "action": "Create .gitignore file with Python, mitmproxy, editor, and OS-specific exclusions",
      "input": "Knowledge of project type (Python/mitmproxy security tool)",
      "output": ".gitignore file with appropriate patterns",
      "file": ".gitignore"
    },
    {
      "step": 2,
      "action": "Initialize git repository",
      "input": "Current directory",
      "output": "Initialized .git directory",
      "file": ".git/"
    },
    {
      "step": 3,
      "action": "Stage all files for commit",
      "input": "All project files",
      "output": "Staged files in git index",
      "file": "N/A"
    },
    {
      "step": 4,
      "action": "Create initial commit with descriptive message",
      "input": "Staged files",
      "output": "Initial commit hash",
      "file": "N/A"
    }
  ],
  "success_criteria": {
    "per_step": [
      "Verify .gitignore exists and contains Python/mitmproxy patterns",
      "Verify .git directory exists",
      "Verify git status shows staged files",
      "Verify git log shows initial commit"
    ],
    "overall": "Git repository initialized with proper .gitignore and initial commit containing all project files"
  }
}

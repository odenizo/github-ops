#!/usr/bin/env node

/**
 * GitHub HQ - Coding Agent Runner
 * Executes AI agent tasks using Anthropic Claude with MCP tools
 */

const Anthropic = require("@anthropic-ai/sdk");
const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

// Initialize Anthropic client
const client = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

// Define available tools for the agent
const tools = [
  {
    name: "execute_shell",
    description:
      "Execute a shell command and return stdout/stderr output. Use for running git, npm, file operations, etc.",
    input_schema: {
      type: "object",
      properties: {
        command: {
          type: "string",
          description: "Shell command to execute (bash/sh syntax)",
        },
        working_dir: {
          type: "string",
          description:
            "Working directory for command execution (defaults to current directory)",
        },
      },
      required: ["command"],
    },
  },
  {
    name: "read_file",
    description: "Read the contents of a file from the repository",
    input_schema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Path to file (relative to repository root)",
        },
      },
      required: ["path"],
    },
  },
  {
    name: "write_file",
    description: "Write or overwrite a file in the repository",
    input_schema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Path to file (relative to repository root)",
        },
        content: {
          type: "string",
          description: "File content to write",
        },
      },
      required: ["path", "content"],
    },
  },
  {
    name: "list_files",
    description: "List files in a directory",
    input_schema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description:
            "Directory path (relative to repo root, defaults to current dir)",
        },
      },
      required: [],
    },
  },
];

/**
 * Process tool calls from the agent
 */
async function processTool(name, input) {
  try {
    switch (name) {
      case "execute_shell": {
        const { command, working_dir } = input;
        const cwd = working_dir || process.cwd();

        try {
          const result = execSync(command, {
            encoding: "utf-8",
            cwd: cwd,
            stdio: ["pipe", "pipe", "pipe"],
          });
          return {
            success: true,
            output: result,
            stderr: "",
          };
        } catch (error) {
          return {
            success: false,
            output: error.stdout || "",
            stderr: error.stderr || error.message,
            exitCode: error.status,
          };
        }
      }

      case "read_file": {
        const { path: filePath } = input;
        try {
          const content = fs.readFileSync(filePath, "utf-8");
          return {
            success: true,
            content: content,
          };
        } catch (error) {
          return {
            success: false,
            error: error.message,
          };
        }
      }

      case "write_file": {
        const { path: filePath, content } = input;
        try {
          // Create directory if needed
          const dir = path.dirname(filePath);
          if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
          }

          fs.writeFileSync(filePath, content, "utf-8");
          return {
            success: true,
            message: `File written: ${filePath}`,
          };
        } catch (error) {
          return {
            success: false,
            error: error.message,
          };
        }
      }

      case "list_files": {
        const { path: dirPath } = input;
        try {
          const targetPath = dirPath || ".";
          const files = fs.readdirSync(targetPath);
          const detailed = files.map((f) => {
            const fullPath = path.join(targetPath, f);
            const stat = fs.statSync(fullPath);
            return {
              name: f,
              type: stat.isDirectory() ? "directory" : "file",
              size: stat.size,
            };
          });
          return {
            success: true,
            files: detailed,
          };
        } catch (error) {
          return {
            success: false,
            error: error.message,
          };
        }
      }

      default:
        return {
          success: false,
          error: `Unknown tool: ${name}`,
        };
    }
  } catch (error) {
    return {
      success: false,
      error: error.message,
    };
  }
}

/**
 * Run the agent with agentic loop
 */
async function runAgent(taskDescription, model = "claude-3-5-sonnet-20241022") {
  console.log("🤖 Starting Coding Agent");
  console.log(`📋 Task: ${taskDescription}`);
  console.log(`🧠 Model: ${model}`);
  console.log("━".repeat(60));

  const messages = [
    {
      role: "user",
      content: taskDescription,
    },
  ];

  let iterationCount = 0;
  const maxIterations = 20;

  while (iterationCount < maxIterations) {
    iterationCount++;
    console.log(`\n🔄 Iteration ${iterationCount}`);

    try {
      // Call Claude with tools
      const response = await client.messages.create({
        model: model,
        max_tokens: 4096,
        tools: tools,
        messages: messages,
      });

      console.log(`   Stop reason: ${response.stop_reason}`);

      // Check if we're done
      if (response.stop_reason === "end_turn") {
        console.log("\n✅ Agent completed task");

        // Extract and print final response
        const textBlock = response.content.find((c) => c.type === "text");
        if (textBlock) {
          console.log("\n📝 Agent Response:");
          console.log("━".repeat(60));
          console.log(textBlock.text);
          console.log("━".repeat(60));
        }
        break;
      }

      // Process tool calls
      if (response.stop_reason === "tool_use") {
        const toolUseBlocks = response.content.filter(
          (c) => c.type === "tool_use"
        );

        if (toolUseBlocks.length === 0) {
          console.log("   No tool calls found, stopping");
          break;
        }

        // Add assistant response to messages
        messages.push({
          role: "assistant",
          content: response.content,
        });

        // Process each tool call
        const toolResults = [];
        for (const toolUse of toolUseBlocks) {
          console.log(`   🔧 Tool: ${toolUse.name}`);

          const result = await processTool(toolUse.name, toolUse.input);
          console.log(`   ✓ Result: ${result.success ? "success" : "error"}`);

          toolResults.push({
            type: "tool_result",
            tool_use_id: toolUse.id,
            content: JSON.stringify(result),
          });
        }

        // Add tool results to messages
        messages.push({
          role: "user",
          content: toolResults,
        });
      }
    } catch (error) {
      console.error("\n❌ Error during agent execution:");
      console.error(error.message);
      throw error;
    }
  }

  if (iterationCount >= maxIterations) {
    console.warn("\n⚠️  Max iterations reached");
  }

  console.log("\n" + "━".repeat(60));
  console.log("🏁 Agent execution complete");
}

/**
 * Main entry point
 */
async function main() {
  const task = process.argv[2] || "List all files in the current directory";

  if (!process.env.ANTHROPIC_API_KEY) {
    console.error(
      "❌ Error: ANTHROPIC_API_KEY environment variable not set"
    );
    process.exit(1);
  }

  try {
    await runAgent(task);
  } catch (error) {
    console.error("\n❌ Fatal error:");
    console.error(error);
    process.exit(1);
  }
}

main();

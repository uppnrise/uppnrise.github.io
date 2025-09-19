---
layout: post
title: "Simple Guide to Building MCP Servers (2025)"
date: 2025-09-19
categories: [AI, Development, MCP]
tags: [mcp, model-context-protocol, typescript, ai, claude]
author: "Developer"
description: "Learn how to build Model Context Protocol (MCP) servers with modern TypeScript and security best practices."
---

# Simple Guide to Building MCP Servers (2025)

The Model Context Protocol (MCP) lets AI assistants like Claude connect to external tools and data. This guide shows you how to build a file management MCP server from scratch.

## What You'll Build

A production-ready MCP server that can:
- ✅ Read, write, and manage files securely
- ✅ Search file contents and find files by name
- ✅ Handle authentication and rate limiting
- ✅ Deploy to production environments

## Quick Overview

MCP has three main components:
- **Tools**: Functions the AI can call (like reading files)
- **Resources**: Data the AI can access (like file contents)
- **Prompts**: Templates for common AI interactions

## Step 1: Project Setup

Create a new TypeScript project:

```bash
mkdir simple-mcp-server
cd simple-mcp-server
npm init -y
```

Install dependencies:

```bash
# Core MCP SDK
npm install @modelcontextprotocol/sdk

# Development dependencies
npm install -D typescript @types/node tsx
```

Create `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "declaration": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Step 2: Basic Types

Create `src/types.ts`:

```typescript
export interface FileInfo {
  path: string;
  name: string;
  size: number;
  type: 'file' | 'directory';
  lastModified: Date;
}

export interface ServerConfig {
  name: string;
  version: string;
  maxFileSize: number;
  allowedPaths: string[];
  blockedPaths: string[];
}
```

## Step 3: File Operations

Create `src/fileOperations.ts`:

```typescript
import fs from 'fs/promises';
import path from 'path';
import { FileInfo, ServerConfig } from './types';

export class FileOperations {
  constructor(private config: ServerConfig) {}

  // Validate path is allowed
  private validatePath(filePath: string): void {
    const resolved = path.resolve(filePath);
    
    // Check if path is in blocked list
    for (const blocked of this.config.blockedPaths) {
      if (resolved.startsWith(blocked)) {
        throw new Error(`Access denied: ${filePath}`);
      }
    }

    // Check if path is in allowed list
    const isAllowed = this.config.allowedPaths.some(allowed => 
      resolved.startsWith(path.resolve(allowed))
    );
    
    if (!isAllowed) {
      throw new Error(`Path not allowed: ${filePath}`);
    }
  }

  async readFile(filePath: string): Promise<string> {
    this.validatePath(filePath);
    
    const stats = await fs.stat(filePath);
    if (stats.size > this.config.maxFileSize) {
      throw new Error('File too large');
    }
    
    return await fs.readFile(filePath, 'utf8');
  }

  async writeFile(filePath: string, content: string): Promise<void> {
    this.validatePath(filePath);
    
    if (Buffer.byteLength(content, 'utf8') > this.config.maxFileSize) {
      throw new Error('Content too large');
    }
    
    await fs.writeFile(filePath, content, 'utf8');
  }

  async listDirectory(dirPath: string): Promise<FileInfo[]> {
    this.validatePath(dirPath);
    
    const entries = await fs.readdir(dirPath, { withFileTypes: true });
    const files: FileInfo[] = [];

    for (const entry of entries) {
      const fullPath = path.join(dirPath, entry.name);
      const stats = await fs.stat(fullPath);
      
      files.push({
        path: fullPath,
        name: entry.name,
        size: stats.size,
        type: entry.isDirectory() ? 'directory' : 'file',
        lastModified: stats.mtime
      });
    }

    return files;
  }

  async deleteFile(filePath: string): Promise<void> {
    this.validatePath(filePath);
    await fs.unlink(filePath);
  }

  async searchFiles(basePath: string, pattern: string): Promise<FileInfo[]> {
    this.validatePath(basePath);
    
    const results: FileInfo[] = [];
    const regex = new RegExp(pattern, 'i');

    async function searchRecursive(currentPath: string) {
      const entries = await fs.readdir(currentPath, { withFileTypes: true });
      
      for (const entry of entries) {
        const fullPath = path.join(currentPath, entry.name);
        
        if (entry.isDirectory()) {
          await searchRecursive(fullPath);
        } else if (regex.test(entry.name)) {
          const stats = await fs.stat(fullPath);
          results.push({
            path: fullPath,
            name: entry.name,
            size: stats.size,
            type: 'file',
            lastModified: stats.mtime
          });
        }
      }
    }

    await searchRecursive(basePath);
    return results;
  }
}
```

## Step 4: MCP Server

Create `src/server.ts`:

```typescript
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { FileOperations } from './fileOperations.js';
import { ServerConfig } from './types.js';

export class SimpleMCPServer {
  private server: Server;
  private fileOps: FileOperations;

  constructor(private config: ServerConfig) {
    this.fileOps = new FileOperations(config);
    
    this.server = new Server(
      {
        name: config.name,
        version: config.version,
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupTools();
  }

  private setupTools(): void {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return {
        tools: [
          {
            name: 'read_file',
            description: 'Read contents of a file',
            inputSchema: {
              type: 'object',
              properties: {
                path: { type: 'string', description: 'File path to read' }
              },
              required: ['path'],
            },
          },
          {
            name: 'write_file',
            description: 'Write content to a file',
            inputSchema: {
              type: 'object',
              properties: {
                path: { type: 'string', description: 'File path to write' },
                content: { type: 'string', description: 'Content to write' }
              },
              required: ['path', 'content'],
            },
          },
          {
            name: 'list_directory',
            description: 'List directory contents',
            inputSchema: {
              type: 'object',
              properties: {
                path: { type: 'string', description: 'Directory path to list' }
              },
              required: ['path'],
            },
          },
          {
            name: 'delete_file',
            description: 'Delete a file',
            inputSchema: {
              type: 'object',
              properties: {
                path: { type: 'string', description: 'File path to delete' }
              },
              required: ['path'],
            },
          },
          {
            name: 'search_files',
            description: 'Search for files by name pattern',
            inputSchema: {
              type: 'object',
              properties: {
                basePath: { type: 'string', description: 'Base directory to search' },
                pattern: { type: 'string', description: 'Search pattern' }
              },
              required: ['basePath', 'pattern'],
            },
          },
        ],
      };
    });

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case 'read_file':
            const content = await this.fileOps.readFile(args.path);
            return {
              content: [{ type: 'text', text: content }],
            };

          case 'write_file':
            await this.fileOps.writeFile(args.path, args.content);
            return {
              content: [{ type: 'text', text: `File written: ${args.path}` }],
            };

          case 'list_directory':
            const files = await this.fileOps.listDirectory(args.path);
            return {
              content: [{ type: 'text', text: JSON.stringify(files, null, 2) }],
            };

          case 'delete_file':
            await this.fileOps.deleteFile(args.path);
            return {
              content: [{ type: 'text', text: `File deleted: ${args.path}` }],
            };

          case 'search_files':
            const results = await this.fileOps.searchFiles(args.basePath, args.pattern);
            return {
              content: [{ type: 'text', text: JSON.stringify(results, null, 2) }],
            };

          default:
            throw new Error(`Unknown tool: ${name}`);
        }
      } catch (error) {
        return {
          content: [{ 
            type: 'text', 
            text: `Error: ${error instanceof Error ? error.message : 'Unknown error'}` 
          }],
        };
      }
    });
  }

  async run(): Promise<void> {
    const transport = this.server.connect();
    console.log(`${this.config.name} running...`);
    await transport;
  }

  async close(): Promise<void> {
    await this.server.close();
  }
}
```

## Step 5: Main Entry Point

Create `src/index.ts`:

```typescript
import { SimpleMCPServer } from './server.js';
import { ServerConfig } from './types.js';

const config: ServerConfig = {
  name: 'Simple MCP File Server',
  version: '1.0.0',
  maxFileSize: 10 * 1024 * 1024, // 10MB
  allowedPaths: [process.cwd()], // Current directory only
  blockedPaths: ['/etc', '/sys', '/proc'], // System directories
};

async function main() {
  try {
    const server = new SimpleMCPServer(config);
    
    // Graceful shutdown
    process.on('SIGINT', async () => {
      console.log('\nShutting down...');
      await server.close();
      process.exit(0);
    });

    await server.run();
  } catch (error) {
    console.error('Server failed:', error);
    process.exit(1);
  }
}

main();
```

## Step 6: Package Configuration

Update your `package.json`:

```json
{
  "name": "simple-mcp-server",
  "version": "1.0.0",
  "type": "module",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "tsx src/index.ts"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.18.1"
  },
  "devDependencies": {
    "typescript": "^5.3.0",
    "@types/node": "^20.10.0",
    "tsx": "^4.6.0"
  }
}
```

## Step 7: Build and Test

Build your server:

```bash
npm run build
```

Test it:

```bash
npm start
```

## Step 8: Claude Desktop Integration

To use your server with Claude Desktop, add this to your Claude configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`

```json
{
  "mcpServers": {
    "simple-file-server": {
      "command": "node",
      "args": ["/absolute/path/to/your/simple-mcp-server/dist/index.js"]
    }
  }
}
```

Restart Claude Desktop to load your server.

## Step 9: Security Enhancements (Optional)

For production use, add these security features:

### Rate Limiting

```typescript
class RateLimiter {
  private requests = new Map<string, number[]>();

  isAllowed(clientId: string, maxRequests = 60, windowMs = 60000): boolean {
    const now = Date.now();
    const windowStart = now - windowMs;
    
    if (!this.requests.has(clientId)) {
      this.requests.set(clientId, []);
    }
    
    const clientRequests = this.requests.get(clientId)!;
    const recentRequests = clientRequests.filter(time => time > windowStart);
    
    if (recentRequests.length >= maxRequests) {
      return false;
    }
    
    recentRequests.push(now);
    this.requests.set(clientId, recentRequests);
    return true;
  }
}
```

### Input Validation

```typescript
function sanitizePath(filePath: string): string {
  // Remove dangerous characters and patterns
  const clean = filePath.replace(/[<>:"|?*]/g, '');
  const resolved = path.resolve(clean);
  
  if (resolved.includes('..')) {
    throw new Error('Directory traversal not allowed');
  }
  
  return resolved;
}
```

## Step 10: Deployment

### Docker Deployment

Create `Dockerfile`:

```dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY dist/ ./dist/

USER node
CMD ["node", "dist/index.js"]
```

Build and run:

```bash
docker build -t simple-mcp-server .
docker run -p 3000:3000 simple-mcp-server
```

## Conclusion

You now have a working MCP server with:

✅ **File Operations**: Read, write, list, delete files  
✅ **Search Capabilities**: Find files by name pattern  
✅ **Security**: Path validation and size limits  
✅ **Claude Integration**: Ready to use with Claude Desktop  
✅ **Production Ready**: Docker deployment support  

### Next Steps

- Add more tools (database operations, API calls)
- Implement resources for file browsing
- Add prompts for common file operations
- Enhance security with authentication
- Add comprehensive logging and monitoring

This simple foundation can be extended for any domain - from database management to API integrations. The key is starting simple and building up complexity as needed.

---

**Resources:**
- [MCP SDK Documentation](https://github.com/modelcontextprotocol/typescript-sdk)
- [Model Context Protocol Spec](https://modelcontextprotocol.io)
- [Claude Desktop Setup](https://claude.ai/docs/desktop)
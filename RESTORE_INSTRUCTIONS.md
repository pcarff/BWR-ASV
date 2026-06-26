# How to Restore Agent Conversations on a New Machine

This backup archive (`agent_conversations_backup.tar.gz`) contains the complete chronological record, artifacts, and logs of all your agent conversations. To restore them in a new environment:

### Step 1: Copy the Archive
Transfer the `agent_conversations_backup.tar.gz` file to the home directory of your target machine.

### Step 2: Create the Target Directory
Determine whether you are using the IDE client (`antigravity-ide`) or the CLI client (`antigravity`).
On the new machine, open a terminal and run the following command to ensure the local configuration and brain directory structure exists:

**For Antigravity IDE:**
```bash
mkdir -p ~/.gemini/antigravity-ide
```

**For CLI:**
```bash
mkdir -p ~/.gemini/antigravity
```

### Step 3: Extract the Archive
Run the following command to extract the conversation folders directly into the brain workspace:

**For Antigravity IDE:**
```bash
tar -xzf agent_conversations_backup.tar.gz -C ~/.gemini/antigravity-ide/
```

**For CLI:**
```bash
tar -xzf agent_conversations_backup.tar.gz -C ~/.gemini/antigravity/
```

### Step 4: Restore Conversation Databases (Optional)
If you have conversation metadata or databases/protos from another installation, copy them to the target `conversations` directory so that conversation history is indexed:

**For Antigravity IDE:**
```bash
cp -n ~/.gemini/antigravity/conversations/* ~/.gemini/antigravity-ide/conversations/
```

### Verification
Once extracted, all conversation IDs and their history logs will be available under the respective brain folder (e.g., `~/.gemini/antigravity-ide/brain/`) and loaded automatically upon initialization in the new environment.

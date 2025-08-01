import { createHash, createCipheriv, createDecipheriv, randomBytes } from 'crypto';
import { z } from 'zod';

// Credential type definitions
export const CredentialSchema = z.object({
  id: z.string(),
  name: z.string(),
  type: z.string(),
  data: z.record(z.unknown()),
  encrypted: z.boolean().default(false),
  createdAt: z.date(),
  updatedAt: z.date(),
  tags: z.array(z.string()).optional(),
  metadata: z.record(z.unknown()).optional(),
});

export type Credential = z.infer<typeof CredentialSchema>;

export interface CredentialManager {
  store(credential: Omit<Credential, 'id' | 'createdAt' | 'updatedAt'>): Promise<string>;
  retrieve(id: string): Promise<Credential | null>;
  update(id: string, updates: Partial<Credential>): Promise<void>;
  delete(id: string): Promise<void>;
  list(filters?: Record<string, unknown>): Promise<Credential[]>;
  encrypt(data: Record<string, unknown>): Promise<string>;
  decrypt(encryptedData: string): Promise<Record<string, unknown>>;
}

export class SecureCredentialManager implements CredentialManager {
  private readonly algorithm = 'aes-256-gcm';
  private readonly keyDerivationSalt: Buffer;
  private readonly encryptionKey: Buffer;

  constructor(masterKey: string, salt?: Buffer) {
    this.keyDerivationSalt = salt || randomBytes(32);
    this.encryptionKey = this.deriveKey(masterKey);
  }

  private deriveKey(masterKey: string): Buffer {
    return createHash('sha256')
      .update(masterKey)
      .update(this.keyDerivationSalt)
      .digest();
  }

  async encrypt(data: Record<string, unknown>): Promise<string> {
    const iv = randomBytes(16);
    const cipher = createCipheriv(this.algorithm, this.encryptionKey, iv);
    
    const dataString = JSON.stringify(data);
    let encrypted = cipher.update(dataString, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const authTag = cipher.getAuthTag();
    
    return JSON.stringify({
      iv: iv.toString('hex'),
      encrypted,
      authTag: authTag.toString('hex'),
    });
  }

  async decrypt(encryptedData: string): Promise<Record<string, unknown>> {
    const { iv, encrypted, authTag } = JSON.parse(encryptedData);
    
    const decipher = createDecipheriv(this.algorithm, this.encryptionKey, Buffer.from(iv, 'hex'));
    decipher.setAuthTag(Buffer.from(authTag, 'hex'));
    
    let decrypted = decipher.update(encrypted, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    
    return JSON.parse(decrypted);
  }

  async store(credential: Omit<Credential, 'id' | 'createdAt' | 'updatedAt'>): Promise<string> {
    const id = this.generateId();
    const now = new Date();
    
    const encryptedData = await this.encrypt(credential.data);
    
    const fullCredential: Credential = {
      ...credential,
      id,
      data: credential.encrypted ? { encrypted: encryptedData } : credential.data,
      encrypted: credential.encrypted || true,
      createdAt: now,
      updatedAt: now,
    };

    // Store in database (placeholder)
    await this.saveToDatabase(fullCredential);
    
    return id;
  }

  async retrieve(id: string): Promise<Credential | null> {
    // Retrieve from database (placeholder)
    const credential = await this.loadFromDatabase(id);
    
    if (!credential) return null;
    
    if (credential.encrypted && credential.data.encrypted) {
      credential.data = await this.decrypt(credential.data.encrypted as string);
    }
    
    return credential;
  }

  async update(id: string, updates: Partial<Credential>): Promise<void> {
    const existing = await this.loadFromDatabase(id);
    if (!existing) throw new Error(`Credential ${id} not found`);

    const updatedCredential = {
      ...existing,
      ...updates,
      updatedAt: new Date(),
    };

    if (updates.data && existing.encrypted) {
      updatedCredential.data = { encrypted: await this.encrypt(updates.data) };
    }

    await this.saveToDatabase(updatedCredential);
  }

  async delete(id: string): Promise<void> {
    await this.deleteFromDatabase(id);
  }

  async list(filters?: Record<string, unknown>): Promise<Credential[]> {
    return this.listFromDatabase(filters);
  }

  private generateId(): string {
    return `cred_${Date.now()}_${randomBytes(8).toString('hex')}`;
  }

  // Database operations (to be implemented with actual database)
  private async saveToDatabase(credential: Credential): Promise<void> {
    // TODO: Implement with PostgreSQL
    console.log('Saving credential to database:', credential.id);
  }

  private async loadFromDatabase(id: string): Promise<Credential | null> {
    // TODO: Implement with PostgreSQL
    console.log('Loading credential from database:', id);
    return null;
  }

  private async deleteFromDatabase(id: string): Promise<void> {
    // TODO: Implement with PostgreSQL
    console.log('Deleting credential from database:', id);
  }

  private async listFromDatabase(filters?: Record<string, unknown>): Promise<Credential[]> {
    // TODO: Implement with PostgreSQL
    console.log('Listing credentials from database with filters:', filters);
    return [];
  }
}

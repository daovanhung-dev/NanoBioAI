window.NANOBIO_CONFIG = Object.freeze({
  supabaseUrl: 'https://rnwohifdnylqfofkydfl.supabase.co',
  // Public anon key from NanoBioAI/assets/config/auth.env. This is a client key, NOT a service-role key.
  supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJud29oaWZkbnlscWZvZmt5ZGZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkxOTgyOTcsImV4cCI6MjA5NDc3NDI5N30.OSP-oidxYi9YvFSubfmGjtHkmAiJ-kOgIQa9O0W0ig4',
  edgeFunctionName: 'register-early-access',
  appVersion: '1.0.1+4',
  // Set to a verified public APK URL only when you intentionally want a public fallback.
  publicDownloadFallback: '',
  // Local fallback keeps the UI testable before the Supabase function is deployed. It is visibly labeled Demo.
  allowDemoFallback: true,
  requestTimeoutMs: 12000
});

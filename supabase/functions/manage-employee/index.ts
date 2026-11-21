import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const jsonResponse = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed.' }, 405);
  }

  const authorization = request.headers.get('Authorization');
  if (!authorization) return jsonResponse({ error: 'Sign in required.' }, 401);

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    console.error('Required Supabase function environment variables are missing.');
    return jsonResponse({ error: 'Server configuration error.' }, 500);
  }

  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    const { data: authData, error: authError } =
      await callerClient.auth.getUser();
    if (authError || !authData.user) {
      return jsonResponse({ error: 'Invalid session.' }, 401);
    }

    const body = await request.json();
    const action = typeof body.action === 'string' ? body.action : '';
    const farmId = typeof body.farm_id === 'string' ? body.farm_id : '';
    if (!farmId) return jsonResponse({ error: 'Farm is required.' }, 400);

    const { data: ownerMembership, error: membershipError } = await adminClient
      .from('farm_members')
      .select('farm_id')
      .eq('farm_id', farmId)
      .eq('user_id', authData.user.id)
      .eq('role', 'owner')
      .maybeSingle();
    if (membershipError) throw membershipError;
    if (!ownerMembership) {
      return jsonResponse({ error: 'Only the farm owner can manage employees.' }, 403);
    }

    if (action === 'create') {
      const name = typeof body.name === 'string' ? body.name.trim() : '';
      const username =
        typeof body.username === 'string'
          ? body.username.trim().toLowerCase()
          : '';
      const password = typeof body.password === 'string' ? body.password : '';
      const canUsePos = body.can_use_pos === true;
      if (!name) return jsonResponse({ error: 'Name is required.' }, 400);
      if (!/^[a-z0-9._-]{3,30}$/.test(username)) {
        return jsonResponse({
          error: 'Username must be 3–30 characters: letters, numbers, dot, dash, or underscore.',
        }, 400);
      }
      if (password.length < 8) {
        return jsonResponse({ error: 'Password must be at least 8 characters.' }, 400);
      }

      const { data: existingProfile, error: profileLookupError } =
        await adminClient
          .from('profiles')
          .select('id')
          .ilike('username', username)
          .maybeSingle();
      if (profileLookupError) throw profileLookupError;
      if (existingProfile) {
        return jsonResponse({ error: 'Username is already in use.' }, 409);
      }

      const syntheticEmail = `${username}@staff.ngapak.invalid`;
      const { data: created, error: createError } =
        await adminClient.auth.admin.createUser({
          email: syntheticEmail,
          password,
          email_confirm: true,
          user_metadata: { full_name: name, username },
        });
      if (createError) {
        if (createError.message.toLowerCase().includes('already')) {
          return jsonResponse({ error: 'Username is already in use.' }, 409);
        }
        throw createError;
      }

      const employeeId = created.user.id;
      const { error: saveError } = await adminClient
        .from('profiles')
        .update({ full_name: name, username, can_use_pos: canUsePos })
        .eq('id', employeeId);
      if (saveError) {
        await adminClient.auth.admin.deleteUser(employeeId);
        throw saveError;
      }

      const { error: membershipSaveError } = await adminClient
        .from('farm_members')
        .insert({ farm_id: farmId, user_id: employeeId, role: 'employee' });
      if (membershipSaveError) {
        await adminClient.auth.admin.deleteUser(employeeId);
        throw membershipSaveError;
      }

      return jsonResponse({ id: employeeId });
    }

    const employeeId =
      typeof body.employee_id === 'string' ? body.employee_id : '';
    if (!employeeId) {
      return jsonResponse({ error: 'Employee is required.' }, 400);
    }
    const { data: employeeMembership, error: employeeLookupError } =
      await adminClient
        .from('farm_members')
        .select('user_id')
        .eq('farm_id', farmId)
        .eq('user_id', employeeId)
        .eq('role', 'employee')
        .maybeSingle();
    if (employeeLookupError) throw employeeLookupError;
    if (!employeeMembership) {
      return jsonResponse({ error: 'Employee not found.' }, 404);
    }

    if (action === 'delete') {
      const { error } = await adminClient.auth.admin.deleteUser(employeeId);
      if (error) throw error;
      return jsonResponse({ id: employeeId });
    }

    if (action === 'update') {
      const name = typeof body.name === 'string' ? body.name.trim() : '';
      const password =
        typeof body.password === 'string' ? body.password : '';
      const canUsePos =
        typeof body.can_use_pos === 'boolean' ? body.can_use_pos : null;
      if (!name) return jsonResponse({ error: 'Name is required.' }, 400);
      if (password.length > 0 && password.length < 8) {
        return jsonResponse({ error: 'Password must be at least 8 characters.' }, 400);
      }
      const attributes: { user_metadata: { full_name: string }; password?: string } = {
        user_metadata: { full_name: name },
      };
      if (password) attributes.password = password;
      const { error: updateAuthError } =
        await adminClient.auth.admin.updateUserById(employeeId, attributes);
      if (updateAuthError) throw updateAuthError;
      const { error: updateProfileError } = await adminClient
        .from('profiles')
        .update({
          full_name: name,
          ...(canUsePos == null ? {} : { can_use_pos: canUsePos }),
        })
        .eq('id', employeeId);
      if (updateProfileError) throw updateProfileError;
      return jsonResponse({ id: employeeId });
    }

    return jsonResponse({ error: 'Unknown action.' }, 400);
  } catch (error) {
    console.error('manage-employee failed:', error);
    return jsonResponse({ error: 'Unable to manage employee.' }, 500);
  }
});

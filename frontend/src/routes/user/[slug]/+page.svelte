<script lang="ts">
	import { goto } from '$app/navigation';
	import { PUBLIC_API_BASE_URL } from '$env/static/public';
	import type { PageData } from './$types';

	import UserAvatar from '$lib/components/UserAvatar.svelte';
	import ResourceList from '$lib/components/ResourceList.svelte';

	import GlobeIcon from 'phosphor-svelte/lib/GlobeIcon';
	import BookIcon from 'phosphor-svelte/lib/BookIcon';
	import ProhibitIcon from 'phosphor-svelte/lib/ProhibitIcon';
	import SignOutIcon from 'phosphor-svelte/lib/SignOutIcon';

	let { data }: { data: PageData } = $props();
	const { user, resources } = data;

	let isOwnProfile = $derived(data.me?.username === user?.username);

	async function logout() {
		await fetch(`${PUBLIC_API_BASE_URL}/auth/logout`, {
			method: 'POST',
			credentials: 'include'
		});
		goto('/auth', { invalidateAll: true });
	}
</script>

<div
	class="bg-zinc-100 flex justify-center pt-4 pb-6 min-h-screen relative overflow-hidden px-4 md:px-0"
>
	<div class="relative z-10 w-full max-w-4xl">
		{#if user}
			<div class="bg-zinc-50 border border-zinc-300">
				<div class="p-4 border-b border-zinc-300 flex items-center gap-4">
					<UserAvatar username={user.username} size="lg" />
					<div class="flex flex-col min-w-0 flex-1">
						<h1 class="text-2xl text-zinc-900">@{user.username}</h1>
						<div class="flex flex-wrap gap-x-4 gap-y-1 mt-1">
							{#if user.studyName}
								<span class="flex items-center gap-1 text-sm text-zinc-500">
									<BookIcon class="size-4 shrink-0 text-zinc-400" />
									{user.studyName}
								</span>
							{/if}
							{#if user.hd}
								<span class="flex items-center gap-1 text-sm text-zinc-500">
									<GlobeIcon class="size-4 shrink-0 text-zinc-400" />
									{user.hd}
								</span>
							{/if}
						</div>
					</div>
					{#if isOwnProfile}
						<button
							onclick={logout}
							class="flex items-center gap-2 px-2 py-2 text-sm text-red-700 bg-red-100 hover:bg-red-50 border border-red-100 transition-colors cursor-pointer"
						>
							Cerrar sesión
						</button>
					{/if}
				</div>

				<div class="p-3 border-b border-zinc-300">
					<h2 class="text-lg text-zinc-700">Recursos compartidos</h2>
				</div>

				<ResourceList
					{resources}
					currentUserId={data.me?.id}
					showSubject
					emptyMessage="Este usuario todavía no ha compartido recursos."
				/>
			</div>
		{:else}
			<div
				class="bg-zinc-50 border border-zinc-300 flex flex-col items-center justify-center py-24 px-8 gap-4"
			>
				<ProhibitIcon weight="thin" class="size-16 text-zinc-400" />
				<h1 class="text-2xl text-zinc-600">Usuario no encontrado</h1>
				<p class="text-zinc-500 text-center">
					El usuario que buscas no existe o no está disponible.
				</p>
				<a
					href="/"
					class="flex items-center bg-zinc-100 border border-zinc-300 text-zinc-600 px-4 py-2 hover:bg-zinc-200 cursor-pointer rounded-none text-sm"
				>
					Volver al inicio
				</a>
			</div>
		{/if}
	</div>
</div>

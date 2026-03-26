<script lang="ts">
	import type { PageData } from './$types';

	import UserAvatar from '$lib/components/UserAvatar.svelte';
	import ResourceList from '$lib/components/ResourceList.svelte';

	import GlobeIcon from 'phosphor-svelte/lib/GlobeIcon';
	import BookIcon from 'phosphor-svelte/lib/BookIcon';
	import ProhibitIcon from 'phosphor-svelte/lib/ProhibitIcon';

	let { data }: { data: PageData } = $props();
	const { user, resources } = data;
</script>

<div class="bg-zinc-100 flex justify-center pt-4 pb-6 min-h-screen relative overflow-hidden px-4 md:px-0">
	<div class="relative z-10 w-full max-w-4xl">
		{#if user}
			<div class="bg-zinc-50 border border-zinc-300">
				<div class="p-4 border-b border-zinc-300 flex items-center gap-4">
					<UserAvatar username={user.username} size="lg" />
					<div class="flex flex-col min-w-0">
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

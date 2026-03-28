<script lang="ts">
	import '../app.css';
	import type { LayoutData } from './$types';
	import { page } from '$app/state';

	import GlobeIcon from 'phosphor-svelte/lib/GlobeIcon';
	import HouseIcon from 'phosphor-svelte/lib/HouseIcon';
	import ShapesIcon from 'phosphor-svelte/lib/ShapesIcon';
	import UserIcon from 'phosphor-svelte/lib/UserIcon';

	let props = $props<{ data: LayoutData; children: () => unknown }>();

	let currentPath = $derived(page.url.pathname);
</script>

{#if currentPath.includes('/auth')}
	{@render props.children?.()}
{:else}
	<div class="min-h-screen flex flex-col bg-zinc-100 transition-all pb-16 md:pb-0">
		<div class="bg-zinc-100/70 backdrop-blur-lg z-50 flex items-center justify-between px-4 py-2">
			<a
				href="/"
				class="h-10 text-2xl text-zinc-700 px-4 py-2 transition-colors inline-flex items-center cursor-pointer"
			>
				<img src="/favicon.svg" alt="Logo" class="size-6 mr-3" />
				nemsy
			</a>

			<div class="hidden md:flex flex-1 justify-center">
				<ul class="flex list-none bg-zinc-50 rounded-none">
					<li>
						<a
							class="h-10 flex items-center px-6 py-2 transition-colors
							{currentPath === '/'
								? 'bg-zinc-200 text-zinc-700 border-zinc-200 border-l border-t border-b hover:bg-zinc-300'
								: 'bg-zinc-100 border-zinc-300 border-l border-t border-b text-zinc-700 hover:bg-zinc-300'}"
							href="/"
							><HouseIcon class="size-5 mr-2" />Inicio
						</a>
					</li>
					<li>
						<a
							class="h-10 flex items-center px-6 py-2 transition-colors
							{currentPath === '/search'
								? 'bg-zinc-200 text-zinc-700 border-zinc-200 border hover:bg-zinc-300'
								: 'bg-zinc-100 border-zinc-300 border text-zinc-700 hover:bg-zinc-300'}"
							href="/search"><GlobeIcon class="size-5 mr-2" />Búsqueda Global</a
						>
					</li>
					<li>
						<a
							class="h-10 flex items-center px-6 py-2 transition-colors
							{currentPath === '/create'
								? 'bg-zinc-200 text-zinc-700 border-zinc-200 border-r border-t border-b hover:bg-zinc-300'
								: 'bg-zinc-100 border-zinc-300 border-r border-t border-b text-zinc-700 hover:bg-zinc-300'}"
							href="/create"><ShapesIcon class="size-5 mr-2" />Compartir</a
						>
					</li>
				</ul>
			</div>

			<div class="hidden md:flex flex-none flex-row items-center gap-4">
				{#if props.data.me}
					<a
						href="/user/{props.data.me?.username}"
						class="h-10 flex items-center px-4 py-2 bg-zinc-50 text-zinc-900 border-zinc-300 border rounded-none"
					>
						{props.data.me?.username}
					</a>
				{:else}
					<a
						href="/auth"
						class="h-10 px-4 py-2 bg-blue-200 text-blue-900 hover:bg-blue-100 border-blue-200 border rounded-none transition-colors inline-flex items-center cursor-pointer"
					>
						<svg
							class="mr-2 -ml-1 w-4 h-4"
							aria-hidden="true"
							focusable="false"
							data-prefix="fab"
							data-icon="google"
							role="img"
							xmlns="http://www.w3.org/2000/svg"
							viewBox="0 0 488 512"
						>
							<path
								fill="currentColor"
								d="M488 261.8C488 403.3 391.1 504 248 504 110.8 504 0 393.2 0 256S110.8 8 248 8c66.8 0 123 24.5 166.3 64.9l-67.5 64.9C258.5 52.6 94.3 116.6 94.3 256c0 86.5 69.1 156.6 153.7 156.6 98.2 0 135-70.4 140.8-106.9H248v-85.3h236.1c2.3 12.7 3.9 24.9 3.9 41.4z"
							></path></svg
						>
						Iniciar sesión
					</a>
				{/if}
			</div>
		</div>

		{@render props.children?.()}
	</div>

	<nav
		class="md:hidden fixed bottom-0 left-0 right-0 z-50 bg-zinc-50/70 border-t border-zinc-300 backdrop-blur-lg flex"
	>
		<a
			href="/"
			class="flex-1 flex flex-col items-center justify-center py-2 gap-0.5 text-xs transition-colors
			{currentPath === '/' ? 'text-violet-700 bg-violet-50' : 'text-zinc-500 hover:text-zinc-900'}"
		>
			<HouseIcon class="size-6" />
			Inicio
		</a>
		<a
			href="/create"
			class="flex-1 flex flex-col items-center justify-center py-2 gap-0.5 text-xs transition-colors
			{currentPath === '/create' ? 'text-violet-700 bg-violet-50' : 'text-zinc-500 hover:text-zinc-900'}"
		>
			<ShapesIcon class="size-6" />
			Compartir
		</a>
		{#if props.data.me}
			<a
				href="/user/{props.data.me?.username}"
				class="flex-1 flex flex-col items-center justify-center py-2 gap-0.5 text-xs transition-colors
				{currentPath.startsWith('/user')
					? 'text-violet-700 bg-violet-50'
					: 'text-zinc-500 hover:text-zinc-900'}"
			>
				<UserIcon class="size-6" />
				{props.data.me.username}
			</a>
		{:else}
			<a
				href="/auth"
				class="flex-1 flex flex-col items-center justify-center py-2 gap-0.5 text-xs transition-colors text-zinc-500 hover:text-zinc-900"
			>
				<UserIcon class="size-6" />
				Entrar
			</a>
		{/if}
	</nav>

	<footer class="bg-zinc-200 text-zinc-700 p-10 flex flex-col md:flex-row justify-between gap-8">
		<aside class="flex flex-col md:flex-row items-start md:items-center gap-4 shrink-0">
			<img src="/favicon.svg" alt="Logo" class="size-16 mr-3 grayscale" />
			<p class="text-sm">
				nemsy.org
				<br />
				<span class="text-zinc-700 italic"
					>Recursos académicos compartidos por y para estudiantes</span
				>
			</p>
		</aside>

		<nav class="flex grow flex-col gap-2 flex-1 sm:flex-none">
			<h6 class="text-sm font-bold tracking-wide text-zinc-600 uppercase">Información</h6>
			<a
				href="/"
				class="text-zinc-700 hover:text-zinc-900 hover:underline transition-colors no-underline"
			>
				Sobre nosotros
			</a>
			<a
				href="/"
				class="text-zinc-700 hover:text-zinc-900 hover:underline transition-colors no-underline"
			>
				Contacto
			</a>
		</nav>
		<nav class="flex flex-col gap-2 flex-1 sm:flex-none">
			<h6 class="text-sm font-bold tracking-wide text-zinc-600 uppercase">Legal</h6>
			<a
				href="/tos"
				class="text-zinc-700 hover:text-zinc-900 hover:underline transition-colors no-underline"
			>
				Términos de uso
			</a>
			<a
				href="/privacy"
				class="text-zinc-700 hover:text-zinc-900 hover:underline transition-colors no-underline"
			>
				Política de privacidad
			</a>
			<a
				href="/cookies"
				class="text-zinc-700 hover:text-zinc-900 hover:underline transition-colors no-underline"
			>
				Política de Cookies
			</a>
		</nav>
	</footer>
{/if}

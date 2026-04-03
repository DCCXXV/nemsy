<script lang="ts">
	import '../app.css';
	import type { LayoutData } from './$types';
	import { page } from '$app/state';

	import GithubLogoIcon from 'phosphor-svelte/lib/GithubLogoIcon';
	import GlobeIcon from 'phosphor-svelte/lib/GlobeIcon';
	import HouseIcon from 'phosphor-svelte/lib/HouseIcon';
	import ShapesIcon from 'phosphor-svelte/lib/ShapesIcon';
	import PlusIcon from 'phosphor-svelte/lib/PlusIcon';
	import ShieldCheckIcon from 'phosphor-svelte/lib/ShieldCheckIcon';
	import UserIcon from 'phosphor-svelte/lib/UserIcon';

	let props = $props<{ data: LayoutData; children: () => unknown }>();

	let currentPath = $derived(page.url.pathname);
</script>

{#if currentPath.includes('/auth')}
	{@render props.children?.()}
{:else}
	<div
		class="min-h-screen flex flex-col bg-zinc-100 transition-all {props.data.me
			? 'pb-20'
			: 'pb-0'} md:pb-0"
	>
		<div
			class="z-50 flex items-center justify-between px-4 py-2 {props.data.me
				? 'bg-zinc-100/70 backdrop-blur-lg'
				: 'sticky top-0 md:bg-transparent backdrop-blur-lg md:backdrop-blur-none'}"
		>
			<a
				href="/"
				class="h-10 text-2xl text-zinc-700 px-4 py-2 transition-colors inline-flex items-center cursor-pointer"
			>
				<img src="/favicon.svg" alt="Logo" class="size-6 mr-3" />
				nemsy
			</a>

			<div class="{props.data.me ? 'hidden md:flex' : 'hidden'} flex-1 justify-center">
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

			<div
				class="{props.data.me ? 'hidden md:flex' : 'flex'} flex-none flex-row items-center gap-4"
			>
				{#if props.data.me}
					{#if props.data.me.role === 'admin'}
						<a
							href="/admin"
							class="h-10 flex items-center px-4 py-2 transition-colors
							{currentPath === '/admin'
								? 'bg-amber-200 text-amber-900 border-amber-300 border rounded-none'
								: 'bg-zinc-50 text-zinc-600 border-zinc-300 border rounded-none hover:bg-zinc-200'}"
						>
							<ShieldCheckIcon class="size-5 mr-1" />Admin
						</a>
					{/if}
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

		<main>
			{@render props.children?.()}
		</main>

		{#if props.data.me}
			<a
				href="/create"
				class="md:hidden fixed bottom-20 right-4 z-50 size-18 flex items-center justify-center bg-lime-300/50 text-lime-900 backdrop-blur-sm"
				style="-webkit-backdrop-filter: blur(16px);"
				title="Compartir recurso"
			>
				<PlusIcon weight="regular" class="size-8" />
			</a>
		{/if}
	</div>

	<nav
		class="{props.data.me
			? ''
			: 'hidden'} md:hidden fixed bottom-0 left-0 right-0 z-50 bg-zinc-50/70 border-t border-zinc-300 backdrop-blur-lg flex"
	>
		<a
			href="/"
			class="flex-1 flex flex-col items-center justify-center py-3 gap-1 text-xs transition-colors
			{currentPath === '/' ? 'text-violet-700 bg-violet-100' : 'text-zinc-500 hover:text-zinc-900'}"
		>
			<HouseIcon class="size-7" />
			Inicio
		</a>
		<a
			href="/search"
			class="flex-1 flex flex-col items-center justify-center py-3 gap-1 text-xs transition-colors
			{currentPath === '/search' ? 'text-violet-700 bg-violet-100' : 'text-zinc-500 hover:text-zinc-900'}"
		>
			<GlobeIcon class="size-7" />
			Búsqueda Global
		</a>
		{#if props.data.me}
			<a
				href="/user/{props.data.me?.username}"
				class="flex-1 flex flex-col items-center justify-center py-3 gap-1 text-xs transition-colors
				{currentPath.startsWith('/user')
					? 'text-violet-700 bg-violet-100'
					: 'text-zinc-500 hover:text-zinc-900'}"
			>
				<UserIcon class="size-7" />
				{props.data.me.username}
			</a>
		{:else}
			<a
				href="/auth"
				class="flex-1 flex flex-col items-center justify-center py-3 gap-1 text-xs transition-colors text-zinc-500 hover:text-zinc-900"
			>
				<UserIcon class="size-7" />
				Entrar
			</a>
		{/if}
	</nav>

	<footer class="bg-zinc-200 text-zinc-600 px-10 py-10 flex flex-col gap-8">
		<div class="flex flex-col md:flex-row md:items-center md:justify-between gap-10">
			<div class="flex flex-col gap-3 shrink-0">
				<div class="flex items-center gap-3">
					<img src="/favicon.svg" alt="Logo" class="size-10 grayscale" />
					<span class="text-xl text-zinc-700">nemsy</span>
				</div>
				<p class="text-sm leading-relaxed max-w-md">
					Plataforma de intercambio de apuntes y recursos académicos entre estudiantes
					universitarios. Proyecto de Trabajo de Fin de Grado desarrollado en la Universidad
					Complutense de Madrid.
				</p>
			</div>

			<nav class="flex flex-wrap gap-6 text-lg">
				<a href="/tos" class="hover:text-zinc-900 transition-colors">Condiciones de uso</a>
				<a href="/privacy" class="hover:text-zinc-900 transition-colors">Política de privacidad</a>
				<a href="/cookies" class="hover:text-zinc-900 transition-colors">Política de cookies</a>
			</nav>
		</div>

		<div class="flex justify-between gap-6">
			<div class="text-md text-zinc-400 font-light uppercase tracking-wide flex flex-col gap-1">
				<p>
					Este sitio no utiliza cookies de análisis, publicidad ni de terceros. La única cookie
					presente es una cookie técnica de sesión, estrictamente necesaria para mantener la
					autenticación del usuario. De conformidad con el artículo 22.2 de la Ley 34/2002 de
					Servicios de la Sociedad de la Información y de Comercio Electrónico (LSSI-CE), las
					cookies técnicas están exentas del requisito de consentimiento previo, por lo que no es
					necesario mostrar un banner de aceptación de cookies.
				</p>
				<p class="text-zinc-600 mt-6">
					© 2026 Nemsy. Código fuente disponible bajo la Licencia Pública de la Unión Europea (EUPL
					v1.2)
				</p>
			</div>
			<a
				href="https://github.com/DCCXXV/nemsy"
				target="_blank"
				rel="noopener noreferrer"
				aria-label="GitHub"
				class="text-zinc-500 hover:text-zinc-700 transition-colors"
			>
				<GithubLogoIcon class="size-8 my-2" />
			</a>
		</div>
	</footer>
{/if}

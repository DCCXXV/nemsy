<script lang="ts">
	import { env } from '$env/dynamic/public';
	import MagnifyingGlassIcon from 'phosphor-svelte/lib/MagnifyingGlassIcon';
	import CheckIcon from 'phosphor-svelte/lib/CheckIcon';
	import type { LayoutData } from './$types';
	import type { Study, University } from '$lib/types';
	import { onMount } from 'svelte';
	import HighlightText from '$lib/components/HighlightText.svelte';

	let { data }: { data: LayoutData } = $props();

	let uniQuery = $state('');
	let studyQuery = $state('');
	let loading = $state(false);
	let studies = $state<Study[]>([]);
	let universities = $state<University[]>([]);
	let errorMsg = $state('');
	let selectedStudy = $state<Study | null>(null);
	let selectedUniversity = $state<University | null>(null);
	let uniResolved = $state(false);
	let searchingUnis = $state(false);
	let debounceTimer: ReturnType<typeof setTimeout>;
	let studySearchInput = $state<HTMLInputElement>();

	onMount(() => {
		if (data.me && data.me.studyId == null) {
			if (data.me?.universityId && data.me?.universityName) {
				selectedUniversity = {
					id: data.me.universityId,
					name: data.me.universityName,
					domain: data.me.universityDomain ?? ''
				};
				uniResolved = true;
				loadStudies(data.me.universityId);
			}
		}
	});

	async function searchUniversities() {
		const q = uniQuery.trim();
		if (!q) {
			universities = [];
			return;
		}
		searchingUnis = true;
		try {
			const res = await fetch(
				`${env.PUBLIC_API_BASE_URL}/api/universities/search?q=${encodeURIComponent(q)}`,
				{ credentials: 'include' }
			);
			if (res.ok) {
				universities = await res.json();
			}
		} catch {
			errorMsg = 'Error buscando universidades';
		} finally {
			searchingUnis = false;
		}
	}

	function onUniInput() {
		clearTimeout(debounceTimer);
		debounceTimer = setTimeout(searchUniversities, 300);
	}

	async function selectUniversity(uni: University) {
		selectedUniversity = uni;
		uniResolved = true;
		universities = [];
		uniQuery = '';

		await fetch(`${env.PUBLIC_API_BASE_URL}/api/me/university`, {
			method: 'PUT',
			headers: { 'Content-Type': 'application/json' },
			credentials: 'include',
			body: JSON.stringify({ universityId: uni.id })
		});

		await loadStudies(uni.id);
		setTimeout(() => studySearchInput?.focus(), 50);
	}

	async function loadStudies(universityId: number) {
		loading = true;
		errorMsg = '';
		try {
			const response = await fetch(
				`${env.PUBLIC_API_BASE_URL}/api/universities/${universityId}/studies`,
				{ credentials: 'include' }
			);
			if (response.ok) {
				studies = await response.json();
			} else {
				errorMsg = 'No se pudieron cargar los grados';
			}
		} catch {
			errorMsg = 'Error de conexión';
		} finally {
			loading = false;
		}
	}

	let filteredStudies = $derived(
		studies.filter((study) => study.name?.toLowerCase().includes(studyQuery.toLowerCase()))
	);

	function selectStudy(study: Study) {
		selectedStudy = study;
	}

	function changeUniversity() {
		selectedUniversity = null;
		uniResolved = false;
		selectedStudy = null;
		studies = [];
	}

	async function finish(study: Study | null) {
		if (study == null) {
			errorMsg = 'Debes seleccionar un grado.';
		} else {
			try {
				const response = await fetch(`${env.PUBLIC_API_BASE_URL}/api/me/study`, {
					method: 'PUT',
					headers: { 'Content-Type': 'application/json' },
					credentials: 'include',
					body: JSON.stringify({ studyId: study.id })
				});

				if (response.ok) {
					window.location.href = '/';
				} else {
					errorMsg = 'No se pudo seleccionar el grado';
				}
			} catch {
				errorMsg = 'Error al seleccionar el grado';
			}
		}
	}
</script>

<div class="lg:mx-20 w-full h-full flex flex-col relative">
	{#if data.me && data.me.studyId == null}
		{#if !uniResolved}
			{#if !data.me.universityId}
				<p class="bg-violet-100 border-violet-700 text-violet-700 pl-4 py-2 mb-4">
					<span class="font-medium">@{data.me.email.split('@')[1]}</span> no está registrado como un correo
					educacional, por lo tanto no hemos podido preseleccionar su universidad.
				</p>
			{/if}
			<p class="text-xl text-zinc-700 mb-2">Selecciona tu universidad:</p>
			<div class="w-full flex border border-zinc-300 bg-zinc-50 mb-4 items-center">
				<MagnifyingGlassIcon class="mx-2 size-5 text-zinc-400" />
				<input
					type="search"
					class="grow border-0 focus:outline-none focus:ring-0 bg-zinc-50 py-2"
					placeholder="Buscar universidad..."
					spellcheck="false"
					bind:value={uniQuery}
					oninput={onUniInput}
				/>
			</div>
			{#if searchingUnis}
				<p class="text-center text-zinc-500">Buscando...</p>
			{:else if universities.length > 0}
				<div class="bg-zinc-50 border border-zinc-300 overflow-auto max-h-1/2">
					{#each universities as uni (uni.id)}
						<button
							onclick={() => selectUniversity(uni)}
							class="w-full text-left p-2 hover:cursor-pointer transition-colors bg-zinc-50 hover:bg-zinc-100 border-b border-zinc-200 last:border-b-0"
						>
							<h3 class="text-lg text-zinc-800">{uni.name}</h3>
							<span class="text-sm text-zinc-500">{uni.domain}</span>
						</button>
					{/each}
				</div>
			{:else if uniQuery.trim().length > 0}
				<p class="text-zinc-500">No se encontraron universidades.</p>
			{/if}
		{:else}
			{#if data.me?.universityId}
				<p class="text-xl text-zinc-700">Hemos detectado que tu universidad es:</p>
			{/if}
			<div class="bg-zinc-50 my-4 p-2 flex border border-zinc-300 gap-4 items-center">
				<img
					src="https://www.google.com/s2/favicons?domain={selectedUniversity?.domain}&sz=64"
					alt="Logo"
					class="border border-zinc-300"
				/>
				<h1 class="text-xl flex-1 text-zinc-800">{selectedUniversity?.name}</h1>
				<button
					onclick={changeUniversity}
					class="text-sm text-zinc-500 hover:text-zinc-700 underline cursor-pointer"
				>
					Cambiar
				</button>
			</div>

			<p class="text-xl text-zinc-700">Selecciona tu grado:</p>
			<div class="w-full flex border border-zinc-300 bg-zinc-50 mb-6 mt-2 items-center">
				<MagnifyingGlassIcon class="mx-2 size-5 text-zinc-400" />
				<input
					type="search"
					class="grow border-0 focus:outline-none focus:ring-0 bg-zinc-50 py-2"
					placeholder="Buscar grado"
					spellcheck="false"
					bind:value={studyQuery}
					bind:this={studySearchInput}
				/>
			</div>
			{#if loading}
				<p class="text-center text-zinc-500">Cargando grados...</p>
			{:else if filteredStudies.length > 0}
				<div class="mb-6 bg-zinc-50 border border-zinc-300 overflow-auto max-h-1/2">
					{#each filteredStudies as study (study.id)}
						<button
							onclick={() => selectStudy(study)}
							class={`w-full text-left p-2 hover:cursor-pointer transition-colors border-b border-zinc-200 last:border-b-0 ${
								selectedStudy?.name == study.name
									? 'bg-zinc-200 hover:bg-zinc-300'
									: 'bg-zinc-50 hover:bg-zinc-100'
							}`}
						>
							<div class="flex items-center justify-between gap-2">
								<h3 class="text-lg">
									<HighlightText text={study.name} query={studyQuery} />
								</h3>
								{#if selectedStudy?.id === study.id}
									<CheckIcon class="size-5 text-zinc-500 shrink-0" />
								{/if}
							</div>
						</button>
					{/each}
				</div>
			{:else if !loading && studies.length === 0}
				<p class="bg-orange-100 border-orange-700 text-orange-700 pl-4 py-2">
					Por el momento solo se soporta la Universidad Complutense de Madrid. Estamos trabajando
					para añadir más universidades próximamente.
				</p>
			{/if}
			{#if errorMsg}
				<p class="bg-rose-100 border-rose-700 text-rose-700 pl-4 py-2 mb-6">
					{errorMsg}
				</p>
			{/if}
			<div class="w-full text-right absolute bottom-0 ml-auto">
				<button
					onclick={() => finish(selectedStudy)}
					class="h-10 px-10 py-2 bg-violet-200 text-violet-900 hover:bg-violet-100 border border-zinc-300 transition-colors inline-flex items-center cursor-pointer text-lg"
				>
					Terminar
				</button>
			</div>
		{/if}
	{:else}
		<div class="my-auto">
			<h1 class="text-4xl text-zinc-700 select-none flex items-center mb-6">
				Te damos la bienvenida a <img
					src="/favicon.svg"
					alt="Nemsy Logo"
					class="size-8 ml-6 mr-2"
				/><span class="text-zinc-700">nemsy</span>
			</h1>
			<p class="bg-orange-100 border-orange-700 text-orange-700 pl-4 py-2">
				Si es tu primer acceso te recomendamos usar tu correo institucional (ej: usuario@ucm.es), en
				caso de disponer de él, para facilitar el proceso de <i>onboarding</i>.
			</p>
			<div class="text-right mt-4">
				<button
					onclick={() => (window.location.href = `${env.PUBLIC_API_BASE_URL}/auth/login`)}
					class="h-10 px-4 py-2 bg-blue-200 hover:bg-blue-100 border-blue-900 text-blue-900 rounded-none transition-colors inline-flex items-center cursor-pointer"
				>
					<svg
						class="mr-2 ml-1 w-4 h-4"
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
						></path>
					</svg>
					Acceso con cuenta de Google
				</button>
			</div>
		</div>
	{/if}
</div>

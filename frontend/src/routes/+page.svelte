<script lang="ts">
	import { PUBLIC_API_BASE_URL } from '$env/static/public';

	import type { PageData } from './$types';
	import { Tabs, Collapsible } from 'bits-ui';
	import type { Subject } from '$lib/types';
	import { page } from '$app/state';
	import { goto, invalidate } from '$app/navigation';
	import { onMount } from 'svelte';

	import { Tooltip } from 'melt/components';

	import PushPinIcon from 'phosphor-svelte/lib/PushPinIcon';

	import CaretDownIcon from 'phosphor-svelte/lib/CaretDownIcon';
	import ResourceList from '$lib/components/ResourceList.svelte';
	import screenshotImg from '$lib/assets/images/screenshot.png';

	let { data }: { data: PageData } = $props();

	let localPinOverrides = $state(new Map<number, boolean>());

	const pinnedIds = $derived(
		new Set(
			data.subjects
				.filter((s) =>
					localPinOverrides.has(s.id) ? localPinOverrides.get(s.id)! : (s.pinned ?? false)
				)
				.map((s) => s.id)
		)
	);
	const pinnedSubjects = $derived(data.subjects.filter((s) => pinnedIds.has(s.id)));

	async function togglePin(subjectId: number) {
		const wasPinned = pinnedIds.has(subjectId);
		localPinOverrides.set(subjectId, !wasPinned);

		const method = wasPinned ? 'DELETE' : 'POST';
		const res = await fetch(`${PUBLIC_API_BASE_URL}/api/me/subjects/${subjectId}/pin`, {
			method,
			credentials: 'include'
		});
		if (!res.ok) {
			localPinOverrides.set(subjectId, wasPinned);
		} else {
			await invalidate('app:subjects');
			localPinOverrides.delete(subjectId);
		}
	}

	const subjectsByYear = $derived(
		data.subjects.reduce(
			(acc, subject) => {
				const year = subject.year || 'Otros';
				if (!acc[year]) acc[year] = [];
				acc[year].push(subject);
				return acc;
			},
			{} as Record<string, Subject[]>
		)
	);

	const yearTabs = $derived(Object.keys(subjectsByYear).sort());
	const tabIds = $derived(['Fijadas', ...yearTabs]);

	const selectedSubjectID = $derived(page.url.searchParams.get('subject'));
	const selectedSubject = $derived(
		data.subjects.find((s) => s.id.toString() === selectedSubjectID)
	);

	let selectedTab = $state('');

	function selectSubject(id: string) {
		localStorage.setItem('lastSubject', id);
	}

	function selectTab(id: string) {
		selectedTab = id;
		localStorage.setItem('lastTab', id);
	}

	function firstSubjectOfYear(): Subject | undefined {
		const firstYear = yearTabs[0];
		if (firstYear && subjectsByYear[firstYear]?.length) {
			return subjectsByYear[firstYear][0];
		}
		return data.subjects[0];
	}

	onMount(() => {
		const savedTab = localStorage.getItem('lastTab');
		if (savedTab && tabIds.includes(savedTab)) {
			selectedTab = savedTab;
		} else {
			selectedTab = yearTabs[0] || 'Fijadas';
		}

		if (!selectedSubjectID) {
			const saved = localStorage.getItem('lastSubject');
			if (saved && data.subjects.some((s) => s.id.toString() === saved)) {
				goto(`?subject=${saved}`, { replaceState: true });
			} else {
				const first = firstSubjectOfYear();
				if (first) {
					selectSubject(first.id.toString());
					goto(`?subject=${first.id}`, { replaceState: true });
				}
			}
		}
	});
</script>

{#if data.me}
	<div class="relative bg-zinc-100 min-h-screen">
		<div
			class="relative z-10 flex flex-col md:flex-row items-stretch md:items-start md:justify-center pt-4 pb-6 gap-4 md:gap-0 px-4 md:px-0"
		>
			<div
				class="bg-zinc-50 border border-zinc-300 rounded-none w-full md:w-1/4 md:ml-4 md:sticky md:top-4"
			>
				<div class="p-2 flex gap-4 items-center border-b border-zinc-300">
					<img
						src="https://www.google.com/s2/favicons?domain={data.me?.universityDomain}&sz=64"
						alt="Logo de {data.me?.universityName}"
						class="rounded-none border border-zinc-300"
					/>
					<p class="text-xl">{data.me?.universityName ?? ''}</p>
				</div>
				<div
					class="px-2 py-1 flex gap-4 items-center text-zinc-700 border-b border-zinc-300 bg-zinc-100"
				>
					<p class="text-lg">Estudio</p>
				</div>
				<div class="p-2 flex gap-4 items-center border-b border-zinc-300">
					<p class="text-lg">Grado en Ingeniería de Software</p>
				</div>
				<Collapsible.Root open>
					<Collapsible.Trigger
						class="group px-2 py-1 w-full flex justify-between items-center text-zinc-700 bg-zinc-100 cursor-pointer data-[state=open]:border-b data-[state=open]:border-zinc-300"
					>
						<p class="text-lg">Asignaturas</p>
						<CaretDownIcon
							class="size-4 transition-transform duration-200 group-data-[state=open]:rotate-180"
						/>
					</Collapsible.Trigger>
					<Collapsible.Content>
						<div class="p-2 flex gap-4 items-center">
							<Tabs.Root value={selectedTab} onValueChange={selectTab} class="w-full">
								<Tabs.List class="flex w-full gap-2">
									{#each tabIds as id (id)}
										<Tabs.Trigger
											value={id}
											class="flex-1 rounded-none px-2 py-1 cursor-pointer border border-zinc-200 transition-colors bg-zinc-100 text-zinc-950 hover:bg-zinc-200 data-[state=active]:bg-violet-200 data-[state=active]:text-violet-900 hover:data-[state=active]:bg-violet-200 text-center"
										>
											{id}
										</Tabs.Trigger>
									{/each}
								</Tabs.List>

								{#each tabIds as id (id)}
									<Tabs.Content value={id}>
										<div class="max-h-[calc(50vh-2rem)] overflow-auto">
											<ul class="pt-2">
												{#if id === 'Fijadas'}
													{#if pinnedSubjects.length}
														{#each pinnedSubjects as subject (subject.id)}
															<a
																href="?subject={subject.id}"
																onclick={() => selectSubject(subject.id.toString())}
																class="block rounded-none py-2 px-2 mb-2 border cursor-pointer
															{selectedSubject?.name == subject?.name
																	? 'bg-lime-200 border-lime-200 text-lime-800'
																	: 'text-zinc-700 bg-zinc-50 hover:bg-zinc-100 border-zinc-50 hover:border-zinc-200'}"
															>
																{subject.name}
															</a>
														{/each}
													{:else}
														<li class="text-zinc-500 py-2 px-2">
															No has fijado ninguna asignatura todavía
														</li>
													{/if}
												{:else if subjectsByYear[id]?.length}
													{#each subjectsByYear[id] as subject (subject.id)}
														<a
															href="?subject={subject.id}"
															onclick={() => selectSubject(subject.id.toString())}
															class="block rounded-none py-2 px-2 mb-2 border cursor-pointer
														{selectedSubject?.name == subject?.name
																? 'bg-lime-200 border-lime-200 text-lime-800'
																: 'text-zinc-700 bg-zinc-50 hover:bg-zinc-100 border-zinc-50 hover:border-zinc-200'}"
														>
															{subject.name}
														</a>
													{/each}
												{:else}
													<li class="text-zinc-500 py-2 px-2">No hay asignaturas</li>
												{/if}
											</ul>
										</div>
									</Tabs.Content>
								{/each}
							</Tabs.Root>
						</div>
					</Collapsible.Content>
				</Collapsible.Root>
			</div>
			<div
				class="bg-zinc-50 border border-zinc-300 rounded-none w-full md:w-1/2 md:mx-4 {data
					.resources.length
					? ''
					: 'border-b-0'}"
			>
				<div class="p-2 border-b border-zinc-300 text-zinc-700 flex items-center justify-between">
					<h1 class="text-2xl">
						{selectedSubject ? selectedSubject.name : 'Fijadas'}
					</h1>

					{#if selectedSubject}
						<Tooltip openDelay={250}>
							{#snippet children(tooltip)}
								<span {...tooltip.trigger}>
									<button
										onclick={() => togglePin(selectedSubject.id)}
										class="flex items-center justify-center cursor-pointer"
									>
										{#if pinnedIds.has(selectedSubject.id)}
											<PushPinIcon weight="fill" class="size-6 text-red-400" />
										{:else}
											<PushPinIcon
												weight="regular"
												class="size-6 text-zinc-500 hover:text-zinc-900"
											/>
										{/if}
									</button>
								</span>
								<div {...tooltip.content}>
									<div {...tooltip.arrow}></div>
									<p class="border border-zinc-300 bg-zinc-50 p-2 text-zinc-500 rounded-none">
										Fijar Asignatura
									</p>
								</div>
							{/snippet}
						</Tooltip>
					{/if}
				</div>
				<div>
					<ResourceList
						resources={data.resources}
						currentUserId={data.me?.id}
						emptyMessage={selectedSubject
							? 'Todavía no hay recursos para esta asignatura.'
							: 'Selecciona una asignatura para ver sus recursos.'}
						emptySubMessage={selectedSubject ? '¿Por qué no ayudas y compartes alguno?' : ''}
					/>
				</div>
			</div>
			<div
				class="hidden md:flex bg-zinc-100 rounded-none w-1/4 mr-4 min-h-136 sticky top-4 flex-col items-center"
			></div>
		</div>
	</div>
{:else}
	<div class="bg-zinc-200">
		<div class="bg-zinc-100 pt-6 pb-24 px-4">
			<div class="max-w-4xl mx-auto text-center">
				<h1 class="text-6xl text-zinc-700 mb-4">nemsy</h1>
				<p class="text-xl text-zinc-500 max-w-xl mx-auto">
					Comparte y accede a <mark class="bg-red-200 text-red-900">apuntes universitarios</mark> con
					facilidad. Todo lo que necesitas para estudiar mejor, en un solo lugar.
				</p>
			</div>
		</div>

		<div class="px-4 -mt-8">
			<div class="max-w-5xl mx-auto">
				<img
					src={screenshotImg}
					alt="Vista de la plataforma"
					class="w-full border border-zinc-300"
				/>
			</div>
		</div>

		<div class="max-w-5xl mx-auto py-24 px-4 flex flex-col gap-24">
			<div class="flex flex-col md:flex-row items-center gap-10">
				<div class="flex-1">
					<h2 class="text-3xl text-zinc-700 mb-3">
						<mark class="bg-yellow-200 text-yellow-900">Open Source</mark>
					</h2>
					<p class="text-zinc-500 text-lg">
						Completamente transparente. Todo el código es público, puedes inspeccionarlo, contribuir
						o adaptarlo. Licenciado bajo la <a
							href="https://interoperable-europe.ec.europa.eu/sites/default/files/custom-page/attachment/eupl_v1.2_es.pdf"
							class="text-indigo-400 underline">Licencia Pública de la Unión Europea</a
						>.
					</p>
				</div>
				<div class="flex-1 flex justify-center">
					<p class="text-8xl font-bold text-zinc-300 text-center leading-none">
						EUPL
						<span class="block text-lg font-normal text-zinc-400 mt-2"
							>Licencia pública europea</span
						>
					</p>
				</div>
			</div>

			<div class="flex flex-col md:flex-row-reverse items-center gap-10">
				<div class="flex-1">
					<h2 class="text-3xl text-zinc-700 mb-3">
						<mark class="bg-blue-200 text-blue-900">Sin anuncios</mark>
					</h2>
					<p class="text-zinc-500 text-lg">
						Valoramos tu tiempo. Sin anuncios embebidos en tus apuntes ni <i>banners</i> o
						<i>popups</i> antes de descargarlos.
					</p>
				</div>
				<div class="flex-1 flex justify-center">
					<p class="text-6xl font-bold text-zinc-300 text-center leading-tight">
						SIN
						<span class="block">ANUNCIOS</span>
					</p>
				</div>
			</div>

			<div class="flex flex-col md:flex-row items-center gap-10">
				<div class="flex-1">
					<h2 class="text-3xl text-zinc-700 mb-3">
						<mark class="bg-lime-200 text-lime-900">Rápido y ligero</mark>
					</h2>
					<p class="text-zinc-500 text-lg">
						Búsca apuntes de tu grado o entre toda la plataforma instantaneamente.
					</p>
				</div>
				<div class="flex-1 flex justify-center">
					<p class="text-8xl font-bold text-zinc-300 text-center leading-none">
						0ms
						<span class="block text-lg font-normal text-zinc-400 mt-2">blocking time</span>
					</p>
				</div>
			</div>
		</div>
	</div>
{/if}

<script lang="ts">
	import type { PageData } from './$types';
	import { Tabs } from 'bits-ui';
	import type { Subject } from '$lib/types';
	import { page } from '$app/state';
	import { goto, invalidate } from '$app/navigation';
	import { onMount } from 'svelte';

	import { Tooltip } from 'melt/components';

	import PushPinIcon from 'phosphor-svelte/lib/PushPinIcon';
	import PencilRulerIcon from 'phosphor-svelte/lib/PencilRulerIcon';
	import ArrowUpRightIcon from 'phosphor-svelte/lib/ArrowUpRightIcon';

	import ResourceList from '$lib/components/ResourceList.svelte';

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

	const tabIds = $derived(['Fijadas', ...Object.keys(subjectsByYear).sort()]);

	const selectedSubjectID = $derived(page.url.searchParams.get('subject'));
	const selectedSubject = $derived(
		data.subjects.find((s) => s.id.toString() === selectedSubjectID)
	);

	let selectedTab = $state(tabIds[0]);

	function selectSubject(id: string) {
		localStorage.setItem('lastSubject', id);
	}

	function selectTab(id: string) {
		selectedTab = id;
		localStorage.setItem('lastTab', id);
	}

	onMount(() => {
		const savedTab = localStorage.getItem('lastTab');
		if (savedTab && tabIds.includes(savedTab)) selectedTab = savedTab;

		if (!selectedSubjectID) {
			const saved = localStorage.getItem('lastSubject');
			if (saved) goto(`?subject=${saved}`, { replaceState: true });
		}
	});
</script>

{#if data.me}
	<div class="relative bg-zinc-100 min-h-screen">
		<div class="relative z-10 flex flex-col md:flex-row items-stretch md:items-start md:justify-center pt-4 pb-6 gap-4 md:gap-0 px-4 md:px-0">
			<div class="bg-zinc-50 border border-zinc-300 rounded-none w-full md:w-1/4 md:ml-4 md:sticky md:top-4">
				<div class="p-2 flex gap-4 items-center border-b border-zinc-300">
					<img
						src="https://www.google.com/s2/favicons?domain={data.me?.hd}&sz=64"
						alt="Logo de {data.me?.hd}"
						class="rounded-none border border-zinc-300"
					/>
					<p class="text-xl">Universidad Complutense de Madrid</p>
				</div>
				<div class="p-2 flex gap-4 items-center border-b border-zinc-300">
					<p class="text-lg">Grado en Ingeniería de Software</p>
				</div>
				<div
					class="px-2 py-1 flex gap-4 items-center text-zinc-700 border-b border-zinc-300 bg-zinc-100"
				>
					<p class="text-lg">Asignaturas</p>
				</div>
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
			</div>
			<div
				class="bg-zinc-50 border border-zinc-300 rounded-none w-full md:w-1/2 md:mx-4 {data.resources.length
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
				<div
					class="bg-yellow-100 border-b border-yellow-300 text-yellow-700 flex items-center px-2 pb-2 pt-4 justify-between"
				>
					<p>¿Quieres compartir un recurso para esta asignatura?</p>
					<a
						href="/create{selectedSubjectID ? `?subject=${selectedSubjectID}` : ''}"
						class="flex items-center bg-zinc-50 text-sm text-zinc-600 p-1 border border-yellow-300 cursor-pointer hover:underline rounded-none"
					>
						Compartir <ArrowUpRightIcon class="size-4 ml-2" />
					</a>
				</div>

				<div>
					{#if selectedSubject}
						<ResourceList
							resources={data.resources}
							emptyMessage="Todavía no hay recursos para esta asignatura."
							emptySubMessage="¿Por qué no ayudas y compartes alguno?"
						/>
					{:else}
						<p class="text-zinc-500 p-2">Selecciona una asignatura para empezar</p>
					{/if}
				</div>
			</div>
			<div
				class="hidden md:flex text-zinc-400 bg-zinc-50 border border-zinc-300 rounded-none w-1/4 mr-4 min-h-136 sticky top-4 flex-col items-center"
			>
				<div class="m-auto aspect-square text-center p-2">
					<PencilRulerIcon weight="thin" class="size-14 mx-auto" />
					<h3>WIP</h3>
				</div>
			</div>
		</div>
	</div>
{:else}
	<div class="relative min-h-screen bg-zinc-200 flex justify-center items-center">
		<div class="absolute inset-x-0 top-0 h-[calc(3/7*100vh)] bg-zinc-100 z-0"></div>

		<div
			class="relative z-10 flex flex-col lg:flex-row w-full max-w-6xl p-4 lg:p-0 mt-24 lg:mt-0 mb-24"
		>
			<div
				class="flex-1 h-full flex justify-center items-center lg:items-start py-12 border border-zinc-300 rounded-none lg:px-10 bg-zinc-50 shadow-[-8px_8px_0px_#d4d4d8] transition-all hover:shadow-none hover:translate-x-[-8px] hover:translate-y-[8px]"
			>
				<div
					class="max-w-md flex flex-col items-center lg:items-start text-left mx-auto lg:mx-0 w-full p-4"
				>
					<h1 class="text-5xl text-zinc-700">nemsy</h1>
					<p class="py-6">
						Comparte y accede a <mark class="bg-red-200 text-red-900">apuntes universitarios</mark> con
						facilidad. Todo lo que necesitas para estudiar mejor, en un solo lugar.
					</p>

					<div class="grid gap-3 mb-6 w-full">
						<div class="flex items-center gap-2 justify-start">
							<span
								><mark class="bg-yellow-200 text-yellow-900">Open Source</mark> = transparente y colaborativo.</span
							>
						</div>
						<div class="flex items-center gap-2 justify-start">
							<span
								><mark class="bg-blue-200 text-blue-900">Sin anuncios</mark> = tu atención en lo que importa.</span
							>
						</div>
						<div class="flex items-center gap-2 justify-start">
							<span
								><mark class="bg-lime-200 text-lime-900">Rápido y ligero</mark> = acceso instantáneo a
								tus apuntes.</span
							>
						</div>
					</div>
				</div>
			</div>

			<div class="flex-1 h-full flex justify-center items-center p-4 rounded-none-xl">
				<div class="w-full max-w-md text-base-100">
					<div style="height: 400px;"></div>
				</div>
			</div>
		</div>
	</div>
{/if}

<script lang="ts">
	import { PUBLIC_API_BASE_URL } from '$env/static/public';

	import type { PageData } from './$types';
	import { Tabs } from 'bits-ui';
	import type { Subject, Resource } from '$lib/types';
	import { page } from '$app/state';
	import { goto, invalidate } from '$app/navigation';
	import { onMount, untrack } from 'svelte';

	import { Tooltip } from 'melt/components';
	import { Dialog } from 'bits-ui';

	import DownloadSimpleIcon from 'phosphor-svelte/lib/DownloadSimpleIcon';
	/*
	import ArrowFatUpIcon from 'phosphor-svelte/lib/ArrowFatUpIcon';
	import ArrowFatDownIcon from 'phosphor-svelte/lib/ArrowFatDownIcon';
	import ArchiveIcon from 'phosphor-svelte/lib/ArchiveIcon';
	import RowsIcon from 'phosphor-svelte/lib/RowsIcon';
	import SquareIcon from 'phosphor-svelte/lib/SquareIcon';
	*/
	import PushPinIcon from 'phosphor-svelte/lib/PushPinIcon';
	import ImagesIcon from 'phosphor-svelte/lib/ImagesIcon';
	import PencilRulerIcon from 'phosphor-svelte/lib/PencilRulerIcon';
	import ArrowUpRightIcon from 'phosphor-svelte/lib/ArrowUpRightIcon';
	import FilePdfIcon from 'phosphor-svelte/lib/FilePdfIcon';
	import QuestionIcon from 'phosphor-svelte/lib/QuestionIcon';
	import ClockClockwiseIcon from 'phosphor-svelte/lib/ClockClockwiseIcon';
	import FolderIcon from 'phosphor-svelte/lib/FolderIcon';
	import ImageIcon from 'phosphor-svelte/lib/ImageIcon';
	import MarkdownLogoIcon from 'phosphor-svelte/lib/MarkdownLogoIcon';

	import PdfThumbnail from '$lib/components/PdfThumbnail.svelte';
	import MarkdownViewer from '$lib/components/MarkdownViewer.svelte';
	import ResourceView from '$lib/components/ResourceView.svelte';
	import UserAvatar from '$lib/components/UserAvatar.svelte';

	function getFirstFileExt(resource: Resource): string {
		if (!resource.files?.length) return '';
		const name = resource.files[0].fileName;
		const dot = name.lastIndexOf('.');
		return dot >= 0 ? name.slice(dot + 1).toLowerCase() : '';
	}

	function isImage(ext: string): boolean {
		return ['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext);
	}

	function isPdf(ext: string): boolean {
		return ext === 'pdf';
	}

	function isMarkdown(ext: string): boolean {
		return ext === 'md' || ext === 'markdown';
	}

	let { data }: { data: PageData } = $props();

	const PAGE_SIZE = 10;
	let extraResources = $state<Resource[]>([]);
	let offset = $state(untrack(() => data.resources.length));
	let hasMore = $state(untrack(() => data.resources.length === PAGE_SIZE));
	let loadingMore = $state(false);
	let sentinel = $state<HTMLDivElement | undefined>(undefined);

	const resources = $derived([...data.resources, ...extraResources]);

	$effect(() => {
		void data.resources;
		extraResources = [];
		offset = data.resources.length;
		hasMore = data.resources.length === PAGE_SIZE;
	});

	async function loadMore() {
		if (loadingMore || !hasMore || !selectedSubjectID) return;
		loadingMore = true;
		try {
			const res = await fetch(
				`${PUBLIC_API_BASE_URL}/api/subjects/${selectedSubjectID}/resources?limit=${PAGE_SIZE}&offset=${offset}`,
				{ credentials: 'include' }
			);
			if (res.ok) {
				const next: Resource[] = await res.json();
				extraResources = [...extraResources, ...next];
				offset += next.length;
				hasMore = next.length === PAGE_SIZE;
			}
		} finally {
			loadingMore = false;
		}
	}

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

	let selectedTab = $state(untrack(() => tabIds[0]));
	let compactMode = $state(false);

	function selectSubject(id: string) {
		localStorage.setItem('lastSubject', id);
	}

	function selectTab(id: string) {
		selectedTab = id;
		localStorage.setItem('lastTab', id);
	}

	function selectViewMode(compact: boolean) {
		compactMode = compact;
		localStorage.setItem('compactMode', compact.toString());
	}

	onMount(() => {
		const savedTab = localStorage.getItem('lastTab');
		if (savedTab && tabIds.includes(savedTab)) selectedTab = savedTab;

		const savedCompactMode = localStorage.getItem('compactMode');
		if (savedCompactMode === 'true') compactMode = true;

		if (!selectedSubjectID) {
			const saved = localStorage.getItem('lastSubject');
			if (saved) goto(`?subject=${saved}`, { replaceState: true });
		}

		const observer = new IntersectionObserver(
			(entries) => {
				if (entries[0].isIntersecting) loadMore();
			},
			{ rootMargin: '300px' }
		);
		if (sentinel) observer.observe(sentinel);
		return () => observer.disconnect();
	});
</script>

{#if data.me}
	<div class="relative bg-zinc-100 min-h-screen">
		<div class="relative z-10 flex items-start justify-center pt-4 pb-6">
			<div class="bg-zinc-50 border border-zinc-300 rounded-none w-1/4 ml-4 sticky top-4">
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
				class="bg-zinc-50 border border-zinc-300 rounded-none w-1/2 mx-4 {resources.length
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
				<div class="bg-zinc-100 border-b border-zinc-300 flex items-center py-1 justify-end">
					<div class="text-zinc-500 bg-zinc-100 border-l border-zinc-300">
						<button class="flex gap-1 items-center justify-center px-2">
							<ClockClockwiseIcon class="size-6" />
							<span class="w-20 text-left">Recientes</span>
						</button>
					</div>
					<div class="text-zinc-500 bg-zinc-100 border-l hover:text-zinc-900 border-zinc-300">
						<button
							class="flex gap-1 items-center justify-center cursor-pointer px-2"
							onclick={() => selectViewMode(!compactMode)}
						>
							<ImagesIcon class="size-6" />
							<span class="w-23 text-left">{compactMode ? 'Compacto' : 'Desplegado'}</span>
						</button>
					</div>
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
						{#each resources as resource (resource.id)}
							<Dialog.Root>
								<Dialog.Trigger
									class="border-b last:border-b-0 p-2 border-zinc-200 w-full text-left cursor-pointer"
								>
									{#if compactMode}
										<div class=" flex gap-3">
											{#if resource.files.length > 1}
												<div
													class="w-20 self-stretch rounded-none border border-yellow-400 bg-yellow-400 flex items-center justify-center"
												>
													<FolderIcon weight="fill" class="size-12 text-zinc-50" />
												</div>
											{:else if isPdf(getFirstFileExt(resource))}
												<div
													class="w-20 self-stretch rounded-none border border-red-400 bg-red-400 flex items-center justify-center"
												>
													<FilePdfIcon weight="fill" class="size-12 text-zinc-50" />
												</div>
											{:else if isImage(getFirstFileExt(resource))}
												<div
													class="w-20 self-stretch rounded-none border border-lime-400 bg-lime-400 flex items-center justify-center"
												>
													<ImageIcon weight="fill" class="size-12 text-zinc-50" />
												</div>
											{:else if isMarkdown(getFirstFileExt(resource))}
												<div
													class="w-20 self-stretch rounded-none border border-blue-400 bg-blue-400 flex items-center justify-center"
												>
													<MarkdownLogoIcon weight="fill" class="size-12 text-zinc-50" />
												</div>
											{:else}
												<div
													class="w-20 self-stretch rounded-none border border-violet-400 bg-violet-400 flex items-center justify-center"
												>
													<QuestionIcon weight="fill" class="size-12 text-zinc-50" />
												</div>
											{/if}
											<div class="flex flex-col flex-1 justify-between py-1">
												<div>
													<h2 class="text-base">{resource.title}</h2>
													<p class="text-sm text-zinc-500">
														@{resource.owner?.username}
													</p>
												</div>
												<div class="flex justify-end gap-2">
													<!--
												<button
														class="bg-zinc-100 hover:bg-zinc-200 border border-zinc-300 text-zinc-600 px-2 py-0.5 flex items-center cursor-pointer text-sm"
														><ArchiveIcon class="size-4 mr-1" />Guardar</button
												>-->
													<a href="{PUBLIC_API_BASE_URL}/api/resources/{resource.id}/download">
														<div
															class="bg-blue-200 border border-blue-100 hover:bg-blue-100 text-blue-900 px-2 py-0.5 flex items-center cursor-pointer text-sm rounded-none"
														>
															<DownloadSimpleIcon class="size-4 mr-1" />Descargar
														</div></a
													>
												</div>
											</div>
										</div>
									{:else}
										<div class="border-b last:border-b-0 p-2 border-zinc-200 flex w-full gap-2">
											<div class="flex flex-col gap-2 w-full">
												<div class="flex items-center gap-2">
													{#if resource.owner}
														<UserAvatar username={resource.owner.username} />
													{/if}
													<div class="flex flex-col">
														<h2 class="text-xl -mb-1">{resource.title}</h2>
														<p class="text-md text-zinc-500">
															@{resource.owner?.username}
														</p>
													</div>
												</div>
												<div class="rounded-none overflow-hidden">
													{#if resource.files.length > 1}
														<div
															class="bg-yellow-200 border border-yellow-300 w-full h-36 justify-center flex items-center"
														>
															<FolderIcon weight="fill" class="size-24 text-yellow-500 mr-2" />
														</div>
													{:else if isPdf(getFirstFileExt(resource))}
														<div class="border border-zinc-300">
															<PdfThumbnail
																url="{PUBLIC_API_BASE_URL}/api/resources/{resource.id}/files/{resource
																	.files[0].id}/download"
															/>
														</div>
													{:else if isImage(getFirstFileExt(resource))}
														<img
															class="border border-zinc-300"
															src="{PUBLIC_API_BASE_URL}/api/resources/{resource.id}/files/{resource
																.files[0].id}/download"
															alt="imagen del recurso"
														/>
													{:else if isMarkdown(getFirstFileExt(resource))}
														<div
															class="border border-zinc-300 w-full h-100 overflow-hidden pointer-events-none"
														>
															<MarkdownViewer
																url="{PUBLIC_API_BASE_URL}/api/resources/{resource.id}/files/{resource
																	.files[0].id}/download"
															/>
														</div>
													{:else}
														<div
															class="border border-zinc-300 bg-zinc-100 w-full h-24 justify-center flex items-center"
														>
															<QuestionIcon class="size-12 text-zinc-500 mr-2" />
															<p class="text-2xl text-zinc-500">Formato desconocido</p>
														</div>
													{/if}
												</div>
												<p class="text-zinc-700">{resource.description}</p>
												<div class="flex justify-end mb-4 gap-2">
													<!--
											<button
												class="bg-zinc-100 hover:bg-zinc-200 border border-zinc-300 text-zinc-600 px-3 py-1 flex items-center cursor-pointer"
												><ArchiveIcon class="size-5 mr-2" />Guardar</button
											>-->
													<a href="{PUBLIC_API_BASE_URL}/api/resources/{resource.id}/download">
														<div
															class="bg-blue-200 border border-blue-100 hover:bg-blue-100 text-blue-900 px-3 py-1 flex items-center cursor-pointer rounded-none"
														>
															<DownloadSimpleIcon class="size-5 mr-2" />Descargar
														</div></a
													>
												</div>
											</div>
										</div>
									{/if}
								</Dialog.Trigger>
								<Dialog.Portal>
									<Dialog.Overlay class="fixed inset-0 z-50 bg-black/30" />
									<Dialog.Content
										class="bg-zinc-50 border-zinc-300 outline-hidden fixed left-[50%] top-[50%] z-50 w-full max-w-[calc(100%-8rem)] h-[calc(100svh-4rem)] translate-x-[-50%] translate-y-[-50%] border overflow-hidden"
									>
										<ResourceView {resource} />
									</Dialog.Content>
								</Dialog.Portal>
							</Dialog.Root>
						{/each}
					{:else}
						<p class="text-zinc-500">Selecciona una asignatura para empezar</p>
					{/if}
					<div bind:this={sentinel}></div>
					{#if loadingMore}
						<div class="py-4 text-center text-zinc-400 animate-pulse text-sm">Cargando más...</div>
					{/if}
				</div>
			</div>
			<div
				class="text-zinc-400 bg-zinc-50 border border-zinc-300 rounded-none w-1/4 mr-4 min-h-136 sticky top-4 flex flex-col items-center"
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

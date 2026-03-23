import { PUBLIC_API_BASE_URL } from '$env/static/public';
import type { PageServerLoad } from './$types';
import type { Subject, Resource } from '$lib/types';

export const load: PageServerLoad = async ({ fetch, url, parent, depends }) => {
	depends('app:subjects');
	const { me } = await parent();
	const subjectId = url.searchParams.get('subject');

	let subjects: Subject[] = [];
	let resources: Resource[] = [];

	if (!me) {
		return { subjects, resources };
	}

	try {
		const subjectsRes = await fetch(`${PUBLIC_API_BASE_URL}/api/me/subjects`, {
			credentials: 'include'
		});

		if (subjectsRes.ok) {
			subjects = await subjectsRes.json();
		}

		if (subjectId) {
			const resourcesRes = await fetch(
				`${PUBLIC_API_BASE_URL}/api/subjects/${subjectId}/resources`,
				{
					credentials: 'include'
				}
			);
			if (resourcesRes.ok) {
				resources = await resourcesRes.json();
			}
		}
	} catch (err) {
		console.error('Error fetching subjects:', err);
	}

	return { subjects, resources };
};
